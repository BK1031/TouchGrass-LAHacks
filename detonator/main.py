import time
from datetime import datetime, timedelta
from geopy.distance import geodesic
import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.base_query import FieldFilter

cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

print("Firebase initialized")

db = firestore.client()

def missile_scan():
    """
    Check all missiles that are not marked as detonated
    """
    missiles_ref = db.collection('missiles')
    missiles = missiles_ref.where(filter=FieldFilter("status", "!=", "DETONATED")).get()
    print("Found {} not detonated missiles".format(len(missiles)))
    for missile in missiles:
        launch_time = datetime.fromisoformat(missile.get('launch_time').replace('Z', '+00:00')).replace(tzinfo=None)
        detonation_time = missile.get('detonation_time') # seconds from firebase
        detonation_time = launch_time + timedelta(seconds=detonation_time) # convert to datetime
        if detonation_time < datetime.utcnow():
            delta = (datetime.utcnow() - detonation_time).total_seconds()
            if delta > 1:
                print("Missed detonation {}s ago".format(delta))
                db.collection('missiles').document(missile.id).update({'status': 'DETONATED'})
            else:
                detonate_missile(missile.id)
        else:
            print("Missile {} is still in the air. ETA: {}".format(missile.id, (detonation_time - datetime.utcnow()).total_seconds()))
            if missile.get('status') != 'DEPLOYED':
                db.collection('missiles').document(missile.id).update({'status': 'DEPLOYED'})


def start_missile_listener():
    """
    Listen for new missiles being launched and mark them as deployed
    """
    # Listen for any new documents on the "missiles" collection
    def on_snapshot(doc_snapshot, changes, read_time):
        for change in changes:
            if change.type.name == "MODIFIED":
                missile_id = change.document.id
                missile = change.document
                if missile.to_dict()["status"] == "":
                    print("New missile detected: {}".format(missile_id))
                    db.collection('missiles').document(missile_id).update({'status': 'DEPLOYED'})
                    increment_attempts(missile.to_dict()["user_id"], missile.to_dict()["game_id"])
    
    db.collection("missiles").on_snapshot(on_snapshot)


def detonate_missile(missile_id):
    """
    Detonate a missile
    """
    missile_ref = db.collection('missiles').document(missile_id).get()
    # Get the target coordinates
    missile_lat = missile_ref.get('target_lat')
    missile_long = missile_ref.get('target_long')
    # Get damage and radius
    try:
        max_damage = missile_ref.get('damage')
    except:
        max_damage = 400
    try:
        radius = missile_ref.get('radius')
    except:
        radius = 50

    # Update missile status
    db.collection('missiles').document(missile_id).update({'status': 'DETONATED'})
    
    # Get all players in the game
    game_id = missile_ref.get('game_id')
    game_ref = db.collection('games').document(game_id).collection("players").get()

    hits = []
    for player in game_ref:
        user_ref = db.collection('users').document(player.id).get()
        # Get user's last known coordinates
        user_lat = user_ref.get('current_lat')
        user_long = user_ref.get('current_long')
        # Calculate distance between missile and player
        distance = calculate_distance((user_lat, user_long), (missile_lat, missile_long))
        if distance <= radius:
            print("Player {} was hit by missile {} ({}m from the strike)".format(player.id, missile_id, distance))
            increment_hits(player.id, game_id)
            damage = max(max_damage - int(distance * max_damage / radius), 10)
            print("Player {} took {} damage".format(player.id, damage))
            decrement_points(player.id, game_id, damage)
            hits.append({
                "user_id": player.id,
                "lat": user_lat,
                "long": user_long,
                "damage": damage,
                "distance": distance,
            })
    
    db.collection("missiles").document(missile_id).update({'hits': hits})


def increment_attempts(userID, gameID):
    """
    Update the number of attempts a user has made
    """
    db.collection('games').document(gameID).collection('players').document(userID).update({'attempts': firestore.Increment(1)})

def increment_hits(userID, gameID, num_hits=1):
    """
    Update the number of hits a user has made
    """
    db.collection('games').document(gameID).collection('players').document(userID).update({'hits': firestore.Increment(num_hits)})

def decrement_points(userID, gameID, damage):
    """
    Update the points of a user
    """
    points = db.collection('games').document(gameID).collection('players').document(userID).get().get('points')
    if points - damage < 0:
        damage = points
    db.collection('games').document(gameID).collection('players').document(userID).update({'points': firestore.Increment(-damage)})

def calculate_distance(coord1, coord2):
    """
    Calculate the distance between two coordinates in meters
    """
    return geodesic(coord1, coord2).meters


start_missile_listener()

while True:
    missile_scan()
    time.sleep(0.4)