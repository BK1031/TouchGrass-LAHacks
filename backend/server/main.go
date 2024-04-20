package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"time"

	"cloud.google.com/go/firestore"
	firebase "firebase.google.com/go"
	"github.com/labstack/echo/v4"
	"google.golang.org/api/iterator"
	"google.golang.org/api/option"
)

func httpErrorHandler(err error, c echo.Context) {
	fmt.Println(err)
}

func main() {
	e := echo.New()
	e.HTTPErrorHandler = httpErrorHandler

	fb := initFirebase()
	ge := NewGameEngine(fb)
	go ge.checkMissleDetonation()
	go ge.checkPointsUpdates(fb)
	e.POST("/missle_request", ge.handleMissleRequest)

	e.Start(":3000")

}

type Missle struct {
	ID             string
	Targetlat      float64
	Targetlong     float64
	Detonationtime int
	SentTime       time.Time
	Radius         int
}

type Player struct {
	ID          string
	Currentlat  float64
	Currentlong float64
	Points      int64
}

type Group struct {
	ID      string
	Players map[string]Player
}

type GameEngine struct {
	groups  map[string]Group
	app     *firebase.App
	missles map[string]Missle
}

// JSON Request Body
type SendMissleRequest struct {
	MissleID       string
	UserID         string
	GroupID        string
	TargetLat      float64
	TargetLong     float64
	DetonationTime int
	Radius         int
}

func (ge *GameEngine) checkPointsUpdates(app *firebase.App) {
	time.Sleep(5 * time.Second)
	// get the current points from firestore
	ctx := context.Background()
	client, err := app.Firestore(ctx)
	if err != nil {
		log.Fatalf("Failed to create Firestore client: %v", err)
	}
	defer client.Close()
	game_docs, err := getAllDocuments(ctx, client, "games")
	if err != nil {
		log.Fatalf("Failed to fetch games: %v", err)
	}
	for _, doc := range game_docs {
		gameID := doc.Ref.ID
		player_docs, err := getAllDocuments(ctx, client, fmt.Sprintf("games/%s/players", gameID))
		if err != nil {
			log.Fatalf("Failed to fetch players for group %s: %v", gameID, err)
		}
		for _, pdoc := range player_docs {
			playerID := pdoc.Ref.ID
			points, err := pdoc.DataAt("points")
			if err != nil {
				log.Fatalf("Failed to fetch player data for player %s: %v", playerID, err)
			}
			// update the points in the game engine
			player := ge.groups[gameID].Players[playerID]
			player.Points = points.(int64)
			ge.groups[gameID].Players[playerID] = player
		}
	}

}

func (ge *GameEngine) handleMissleRequest(c echo.Context) error {
	var missleReq SendMissleRequest

	if err := json.NewDecoder(c.Request().Body).Decode(&missleReq); err != nil {
		return err
	}

	newMissile := Missle{
		ID:             missleReq.MissleID,
		Targetlat:      missleReq.TargetLat,
		Targetlong:     missleReq.TargetLong,
		Detonationtime: missleReq.DetonationTime,
		SentTime:       time.Now(),
		Radius:         missleReq.Radius,
	}
	ge.missles[missleReq.MissleID] = newMissile
	ge.addOrUpdateMissleToFirestore(newMissile)

	player := ge.groups[missleReq.GroupID].Players[missleReq.UserID]
	player.Points -= 20 // Deduct points for firing a missile
	ge.groups[missleReq.GroupID].Players[missleReq.UserID] = player
	ge.updatePlayerPointsInFirestore(missleReq.GroupID, missleReq.UserID, player.Points)

	return c.JSON(http.StatusOK, map[string]interface{}{"msg": "MISSLE FIRED"})
}

func (ge *GameEngine) checkMissleDetonation() {
	now := time.Now()
	for missleID, missle := range ge.missles {
		if now.After(missle.SentTime.Add(time.Duration(missle.Detonationtime) * time.Second)) {
			for groupID, group := range ge.groups {
				for playerID, player := range group.Players {
					if distance(player.Currentlat, player.Currentlong, missle.Targetlat, missle.Targetlong) <= float64(missle.Radius) {
						player.Points -= 500 // Deduct points for getting hit
						ge.groups[groupID].Players[playerID] = player
						ge.updatePlayerPointsInFirestore(groupID, playerID, player.Points)
					}
				}
			}
			delete(ge.missles, missleID) // Remove the missile after detonation
		}
	}
}

func distance(lat1, long1, lat2, long2 float64) float64 {
	const earthRadiusKm = 6371 // Radius of the earth in kilometers.

	// Convert latitude and longitude from degrees to radians
	lat1Rad := lat1 * math.Pi / 180
	long1Rad := long1 * math.Pi / 180
	lat2Rad := lat2 * math.Pi / 180
	long2Rad := long2 * math.Pi / 180

	// Haversine formula
	dLat := lat2Rad - lat1Rad
	dLong := long2Rad - long1Rad
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(dLong/2)*math.Sin(dLong/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	distance := earthRadiusKm * c

	return distance
}

func NewGameEngine(app *firebase.App) *GameEngine {
	ctx := context.Background()
	client, err := app.Firestore(ctx)
	if err != nil {
		log.Fatalf("Failed to create Firestore client: %v", err)
	}
	defer client.Close()

	grps := make(map[string]Group)
	// Fetch games  from Firestore
	groupDocs, err := getAllDocuments(ctx, client, "games")
	if err != nil {
		log.Fatalf("Failed to fetch games: %v", err)
	}
	// from each game, fetch all the players in the game
	for _, doc := range groupDocs {
		var group Group
		groupID := doc.Ref.ID
		group.ID = groupID
		playerDocs, err := getAllDocuments(ctx, client, fmt.Sprintf("games/%s/players", groupID))
		if err != nil {
			log.Fatalf("Failed to fetch players for group %s: %v", groupID, err)
		}
		group.Players = make(map[string]Player)
		// for each player in the game, get the players data
		for _, pdoc := range playerDocs {
			var player Player
			playerID := pdoc.Ref.ID
			player.ID = playerID
			player.Points = pdoc.Data()["points"].(int64)

			// the players data is in a different collection

			playerData := getDocument(client, "users", playerID)
			currlat, err := playerData.DataAt("current_lat")
			if err != nil {
				log.Fatalf("Failed to fetch player data for player %s: %v", playerID, err)
			}
			currlong, err := playerData.DataAt("current_long")
			if err != nil {
				log.Fatalf("Failed to fetch player data for player %s: %v", playerID, err)
			}
			player.Currentlat = currlat.(float64)
			player.Currentlong = currlong.(float64)

			group.Players[playerID] = player
		}

		grps[group.ID] = group
	}

	return &GameEngine{groups: grps, app: app, missles: make(map[string]Missle)}
}

func initFirebase() *firebase.App {
	ctx := context.Background()
	sa := option.WithCredentialsFile("battleship-lahacks-firebase-adminsdk-j7rvt-06c45b06f4.json") // Replace with your file path
	app, err := firebase.NewApp(ctx, nil, sa)
	if err != nil {
		log.Fatalf("error initializing app: %v\n", err)
	}
	return app
}

// getAllDocuments retrieves all documents from a specified collection in Firestore.
func getAllDocuments(ctx context.Context, client *firestore.Client, collectionName string) ([]*firestore.DocumentSnapshot, error) {
	var documents []*firestore.DocumentSnapshot
	iter := client.Collection(collectionName).Documents(ctx)
	defer iter.Stop()
	for {
		doc, err := iter.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		documents = append(documents, doc)
	}
	return documents, nil
}

func getDocument(client *firestore.Client, collection string, docID string) *firestore.DocumentSnapshot {
	ctx := context.Background()
	doc, err := client.Collection(collection).Doc(docID).Get(ctx)
	if err != nil {
		log.Printf("Failed to retrieve document: %v", err)
		return nil
	}
	return doc
}

// Adds or updates a missile in Firestore
func (ge *GameEngine) addOrUpdateMissleToFirestore(missle Missle) {
	client, err := ge.app.Firestore(context.Background())
	if err != nil {
		log.Printf("Failed to get Firestore client: %v", err)
		return
	}
	defer client.Close()

	_, err = client.Collection("missiles").Doc(missle.ID).Set(context.Background(), missle)
	if err != nil {
		log.Printf("Failed to add or update missile: %v", err)
	}
}

// Updates player points in Firestore
func (ge *GameEngine) updatePlayerPointsInFirestore(groupID, playerID string, points int64) {
	client, err := ge.app.Firestore(context.Background())
	if err != nil {
		log.Printf("Failed to get Firestore client: %v", err)
		return
	}
	defer client.Close()

	_, err = client.Collection("groups").Doc(groupID).Collection("players").Doc(playerID).Update(context.Background(), []firestore.Update{
		{Path: "points", Value: points},
	})
	if err != nil {
		log.Printf("Failed to update player points: %v", err)
	}
}
