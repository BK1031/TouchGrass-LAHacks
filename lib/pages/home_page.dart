import 'dart:async';
import 'dart:math';
import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/models/player.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:battleship_lahacks/widgets/location_disabled_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  MapboxMapController? mapController;
  Location location = Location();

  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  bool showPoints = false;
  StreamSubscription<QuerySnapshot>? currentGameListener;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
    getGamesForPlayer();
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  Future<void> getUserLocation() async {
    location.enableBackgroundMode(enable: true);
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.warning,
          title: "Location Disabled",
          widget: const Text("Please enable location access while the app is in the background to use this app!"),
          confirmBtnText: "OK",
        );
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.warning,
          title: "Location Disabled",
          widget: const Text("Please enable location access while the app is in the background to use this app!"),
          confirmBtnText: "OK",
        );
        return;
      }
    }
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    location.onLocationChanged.listen((LocationData newPosition) {
      double delta = calculateDistance(currentPosition?.latitude ?? 0, currentPosition?.longitude?? 0, newPosition.latitude!, newPosition.longitude!);
      log("Position update delta: ${delta}m");
      setState(() {
        currentPosition = newPosition;
      });
      log("Current location: ${currentPosition!.latitude}, ${currentPosition!.longitude}");
      if (delta > 20) {
        FirebaseFirestore.instance.collection("users/${currentUser.id}/location_history").add({
          "lat": currentPosition!.latitude,
          "long": currentPosition!.longitude,
          "timestamp": DateTime.now().toUtc().toIso8601String()
        });
      }
      FirebaseFirestore.instance.doc("users/${currentUser.id}").update({
        "current_lat": currentPosition!.latitude!,
        "current_long": currentPosition!.longitude!
      });
    });
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    double p = 0.017453292519943295;
    double a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  Future<void> getGamesForPlayer() async {
    QuerySnapshot gameshot = await FirebaseFirestore.instance.collection("games").get();
    for (int i = 0; i < gameshot.size; i++) {
      String gameID = gameshot.docs.elementAt(i).id;
      QuerySnapshot result = await FirebaseFirestore.instance.collection("games/$gameID/players").where("id", isEqualTo: currentUser.id).get();
      if (result.size == 1) {
        // Player is in this game
        Game game = Game.fromJson(gameshot.docs.elementAt(i).data() as Map<String, dynamic>);
        // Get all players for that game
        QuerySnapshot playershot = await FirebaseFirestore.instance.collection("games/$gameID/players").get();
        for (int i = 0; i < playershot.size; i++) {
          setState(() {
            game.players.add(Player.fromJson(playershot.docs.elementAt(i).data() as Map<String, dynamic>));
          });
        }
        setState(() {
          joinedGames.add(game);
          if (currentGame.id == "") currentGame = game;
          showPoints = true;
        });
      }
    }
    setupListenersForCurrentGame();
  }

  Future<void> setupListenersForCurrentGame() async {
    currentGameListener?.cancel();
    currentGameListener = FirebaseFirestore.instance.collection("games/${currentGame.id}/players").snapshots().listen((event) {
      for (int i = 0; i < event.docs.length; i++) {
        Player playerUpdate = Player.fromJson(event.docs[i].data());
        setState(() {
          currentGame.players[currentGame.players.indexWhere((p) => p.id == playerUpdate.id)] = playerUpdate;
          joinedGames.firstWhere((g) => g.id == currentGame.id).players = currentGame.players;
        });
      }
    });
  }

  Widget _buildGameDropdown() {
    List<DropdownMenuItem<String>> dropdownItems = joinedGames.map((g) => DropdownMenuItem(
      value: g.id,
      child: Text(g.name),
    )).toList();
    dropdownItems.add(const DropdownMenuItem(
      value: "create",
      child: Row(
        children: [
          Icon(Icons.add_rounded),
          Padding(padding: EdgeInsets.all(2)),
          Text("Create or Join", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        ],
      ),
    ));
    return joinedGames.isNotEmpty ? Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 8),
        child: DropdownButton<String>(
          value: currentGame.id != "" ? currentGame.id : "create",
          alignment: Alignment.center,
          underline: Container(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          items: dropdownItems,
          borderRadius: BorderRadius.circular(32),
          onChanged: (item) {
            if (item == "create") {
              router.navigateTo(context, "/game/create", transition: TransitionType.cupertinoFullScreenDialog);
            } else {
              setState(() {
                currentGame = joinedGames.firstWhere((g) => g.id == item);
              });
              setupListenersForCurrentGame();
            }
          },
        ),
      ),
    ) : Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
      child: InkWell(
        onTap: () {
          router.navigateTo(context, "/game/create", transition: TransitionType.cupertinoFullScreenDialog);
        },
        child: const Padding(
          padding: EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
          child: Row(
            children: [
              Icon(Icons.add_rounded),
              Padding(padding: EdgeInsets.all(2)),
              Text("Create or Join Game", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Battleship"),
      ),
      body: currentPosition != null ? Stack(
        children: [
          MapboxMap(
            accessToken: kIsWeb ? MAPBOX_PUBLIC_TOKEN : MAPBOX_ACCESS_TOKEN,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(currentPosition!.latitude!, currentPosition!.longitude!),
              zoom: 14.0,
            ),
            attributionButtonMargins: const Point(-32, -32),
            myLocationEnabled: true,
            dragEnabled: true,
          ),
          Container(
            // color: Colors.greenAccent,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
                      child: InkWell(
                        onTap: () {
                          // setState(() => showPoints = !showPoints);
                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              child: Image.network(currentUser.profilePictureURL, height: 40),
                              borderRadius: BorderRadius.circular(512),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                              width: showPoints ? 90 + (currentGame.players.firstWhere((p) => p.id == currentUser.id).points % 999 > 0 ? 20 : 0) : 0,
                              height: 40,
                              padding: const EdgeInsets.only(left: 8, right: 16),
                              child: showPoints ? Center(
                                child: Text(
                                  "${currentGame.players.firstWhere((p) => p.id == currentUser.id).points} pts",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                                )
                              ) : Container(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildGameDropdown()
                  ],
                )
              ],
            ),
          ),
        ],
      ) : const LocationDisabledCard()
    );
  }
}
