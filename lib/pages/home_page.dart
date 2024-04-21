import 'dart:async';
import 'dart:math';
import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/models/missile.dart';
import 'package:battleship_lahacks/models/player.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/widgets/countdown_text.dart';
import 'package:battleship_lahacks/widgets/drawer_preview_card.dart';
import 'package:battleship_lahacks/widgets/drawer_summary_page.dart';
import 'package:battleship_lahacks/widgets/location_disabled_card.dart';
import 'package:battleship_lahacks/widgets/missile_countdown_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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
  StreamSubscription<DocumentSnapshot>? deployedMissileListener;
  StreamSubscription<QuerySnapshot>? gameMissileListener;
  DateTime ceasefireEnd = DateTime.now();

  bool isDrawerExpanded = false;

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
    OneSignal.login(currentUser.id);
    location.enableBackgroundMode(enable: true);
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.warning,
          title: "Location Disabled",
          widget: const Text(
              "Please enable location access while the app is in the background to use this app!"),
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
          widget: const Text(
              "Please enable location access while the app is in the background to use this app!"),
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
          if (currentGame.id == "" || DateTime.now().isAfter(game.startTime.toLocal())) currentGame = game;
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
          int index = currentGame.players.indexWhere((p) => p.id == playerUpdate.id);
          if (index < 0) {
            // new player just joined
            currentGame.players.add(playerUpdate);
          } else {
            // update existing player
            currentGame.players[index] = playerUpdate;
          }
          currentGame.players.sort((p1, p2) => p2.points.compareTo(p1.points));
          joinedGames.firstWhere((g) => g.id == currentGame.id).players = currentGame.players;
        });
      }
      currentGame.debugPrint();
    });
    listenForGameMissiles();
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
              lastMissile = Missile();
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

  void blinkingMapboxCircle(int seconds, double lat, double long) async {
    int counter = 0;
    Timer t = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      counter++;
      if (counter % 2 == 0) {
        mapController?.addCircle(CircleOptions(
          circleRadius: 25,
          circleColor: "ff0000",
          circleOpacity: 0.5,
          circleStrokeColor: "ff0000",
          circleStrokeOpacity: 1,
          circleStrokeWidth: 5,
          geometry: LatLng(lat, long),
        ));
      } else {
        mapController?.clearCircles();
      }
    });
    Future.delayed(Duration(seconds: seconds), () {
      t.cancel();
    });
  }

  Future<void> initiateWarCrimes() async {
    mapController?.clearCircles();
    double targetLat = mapController!.cameraPosition!.target.latitude;
    double targetLong = mapController!.cameraPosition!.target.longitude;
    Missile missile = Missile();
    missile.userID = currentUser.id;
    missile.gameID = currentGame.id;
    missile.targetLat = targetLat;
    missile.targetLong = targetLong;
    missile.damage = DEFAULT_DAMAGE;
    missile.radius = DEFAULT_RADIUS;
    // missile.detonationTime = DEFAULT_DETONATION_TIME + Random().nextInt(5) * 60;
    missile.detonationTime = 10;
    DocumentReference missileRef = await FirebaseFirestore.instance.collection("missiles").add(missile.toJson());
    missile.id = missileRef.id;
    await FirebaseFirestore.instance.doc("missiles/${missile.id}").update({"id": missile.id});
    blinkingMapboxCircle(missile.detonationTime, targetLat, targetLong);
    setState(() {
      lastMissile.id = missile.id;
    });
    listenForDeployedMissile();
  }

  void listenForDeployedMissile() {
    deployedMissileListener?.cancel();
    deployedMissileListener = FirebaseFirestore.instance.doc("missiles/${lastMissile.id}").snapshots().listen((event) async {
      setState(() {
        lastMissile = Missile.fromJson(event.data()!);
      });
      if (lastMissile.status == "DETONATED") {
        mapController?.clearCircles();
        mapController?.addCircle(CircleOptions(
          circleRadius: 40,
          circleColor: '#ff4631',
          circleOpacity: 0.5,
          circleStrokeColor: '#ff1a00',
          circleStrokeOpacity: 1,
          circleStrokeWidth: 5,
          geometry: LatLng(lastMissile.targetLat, lastMissile.targetLong),
        ));
        await Future.delayed(const Duration(seconds: 5), () {
          mapController?.clearCircles();
          setState(() {
            lastMissile.status = "COOLDOWN";
          });
        });
        if (lastMissile.launchTime.toLocal().add(Duration(seconds: DEFAULT_COOLDOWN)).isAfter(DateTime.now())) {
          // Still need to cooldown
          Duration duration = lastMissile.launchTime.toLocal().add(Duration(seconds: DEFAULT_COOLDOWN)).difference(DateTime.now());
          Future.delayed(duration, () {
            setState(() {
              lastMissile = Missile();
            });
          });
        }
        deployedMissileListener?.cancel();
      }
    });
  }

  Future<void> listenForGameMissiles() async {
    gameMissileListener?.cancel();
    gameMissileListener = FirebaseFirestore.instance.collection("missiles").where("game_id", isEqualTo: currentGame.id).snapshots().listen((event) {
      for (int i = 0; i < event.size; i++) {
        Missile missile = Missile.fromJson(event.docs[i].data());
        int index = currentGame.missiles.indexWhere((m) => m.id == missile.id);
        if (index > -1) {
          currentGame.missiles[index] = missile;
        } else {
          currentGame.missiles.add(missile);
        }
        if (lastMissile.id == "" && missile.userID == currentUser.id && missile.launchTime.toLocal().add(Duration(seconds: DEFAULT_COOLDOWN)).isAfter(DateTime.now())) {
          setState(() {
            lastMissile = missile;
          });
          if (lastMissile.status == "DETONATED") {
            setState(() {
              lastMissile.status = "COOLDOWN";
            });
            Duration duration = lastMissile.launchTime.toLocal().add(Duration(seconds: DEFAULT_COOLDOWN)).difference(DateTime.now());
            Future.delayed(duration, () {
              setState(() {
                lastMissile = Missile();
              });
            });
          }
        }
      }
    });
  }

  bool _canLaunchStrike() {
    return _isGameStarted() && !_isGameEnded() && !_isCeasefire() && !_isCooldown() && lastMissile.status == "";
  }

  bool _isGameStarted() {
    return DateTime.now().isAfter(currentGame.startTime.toLocal());
  }

  bool _isGameEnded() {
    return DateTime.now().isAfter(currentGame.endTime.toLocal());
  }

  bool _isCeasefire() {
    // for (int i = 0; i < currentGame.settings.ceasefireHours.length; i++) {
    //   DateTime t = DateTime.now();
    //   DateTime start = currentGame.settings.ceasefireHours[i].start.toLocal().copyWith(month: t.month, day: t.day, year: t.year);
    //   DateTime end = currentGame.settings.ceasefireHours[i].end.toLocal().copyWith(month: t.month, day: t.day, year: t.year);
    //   if (t.isAfter(end) && t.isAfter(start)) {
    //     start = start.add(const Duration(days: 1));
    //     end = end.add(const Duration(days: 1));
    //   } else if (t.isAfter(end) && t.isBefore(start)) {
    //     end = end.add(const Duration(days: 1));
    //   }
    //   if (t.isAfter(start) && t.isBefore(end)) {
    //     setState(() {
    //       ceasefireEnd = end;
    //     });
    //     return true;
    //   }
    // }
    return false;
  }

  bool _isCooldown() {
    return lastMissile.status == "COOLDOWN";
  }

  MaterialAccentColor missileStatusColor(String status) {
    if (status == "DETONATED") return Colors.redAccent;
    else if (status == "DEPLOYED") return Colors.orangeAccent;
    else if (status == "COOLDOWN") return Colors.amberAccent;
    else return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Battleship"),
      // ),
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
            trackCameraPosition: true,
          ),
          Visibility(
            visible: _canLaunchStrike(),
            child: Center(child: Image.asset("images/crosshair.png", height: 100,))
          ),
          SafeArea(
            child: Container(
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

                          },
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(512),
                                child: Image.network(currentUser.profilePictureURL, height: 40),
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
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 86),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _canLaunchStrike() ? 100 : 0,
                      height: _canLaunchStrike() ? 90 : 0,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          initiateWarCrimes();
                        },
                        color: Colors.redAccent,
                        child: const Text("LAUNCH"),
                      ),
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(8)),
                  Visibility(
                    visible: joinedGames.isEmpty,
                    child: const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.grass_rounded, size: 75, color: Colors.greenAccent,),
                            Padding(padding: EdgeInsets.all(8)),
                            Text("Welcome!", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                            Padding(padding: EdgeInsets.all(4)),
                            Text("We're excited to have you on board. Use the button at the top right to join or crate your first Touch Grass game!", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,),
                          ],
                        ),
                      )
                    ),
                  ),
                  Visibility(
                    visible: _isGameStarted() && !_isGameEnded(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: lastMissile.id == "" ? 50 : lastMissile.status == "DETONATED" ? 200 : 100,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Visibility(
                                  visible: lastMissile.status == "DETONATED",
                                  child: Column(
                                    children: [
                                      const Text("Time elapsed", style: TextStyle(fontSize: 20),),
                                      Text(
                                        "${Duration(seconds: lastMissile.detonationTime).inMinutes.remainder(60)}m ${Duration(seconds: lastMissile.detonationTime).inSeconds.remainder(60)}s",
                                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey),
                                      ),
                                      const Padding(padding: EdgeInsets.all(4)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.electric_bolt_rounded, size: 32, color: Colors.white,),
                                          const Padding(padding: EdgeInsets.all(4)),
                                          Text(lastMissile.hits.length.toString(), style: const TextStyle(fontSize: 20),),
                                          const Padding(padding: EdgeInsets.all(4)),
                                          const Text("Successful Hits", style: TextStyle(fontSize: 20))
                                        ],
                                      ),
                                      const Padding(padding: EdgeInsets.all(8)),
                                    ],
                                  ),
                                ),
                                Visibility(
                                  visible: lastMissile.status == "DEPLOYED" || lastMissile.status == "COOLDOWN",
                                  child: Container(
                                    child: MissileCountdownText(
                                      missile: lastMissile,
                                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("STATUS:", style: TextStyle(fontSize: 20),),
                                    const Padding(padding: EdgeInsets.all(4)),
                                    Text(lastMissile.status != "" ? lastMissile.status : "READY", style: TextStyle(fontSize: 20, color: missileStatusColor(lastMissile.status)))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _isGameStarted() && !_isGameEnded() && _isCeasefire(),
                    child: Card(
                      color: Colors.orangeAccent,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Ceasefire active!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            CountdownText(dateTime: ceasefireEnd, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                            const Text("until it's over", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !_isGameStarted() && !_isGameEnded(),
                    child: Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Game has not started!", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Padding(padding: EdgeInsets.all(2)),
                            CountdownText(dateTime: currentGame.startTime, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const Padding(padding: EdgeInsets.all(2)),
                            const Text("until the game's afoot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: currentGame.players.any((p) => p.id == currentUser.id),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Card(
                      child: InkWell(
                        splashColor: Colors.transparent,
                        onTap: () {
                          setState(() {
                            isDrawerExpanded = !isDrawerExpanded;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: isDrawerExpanded ? 550 : 80,
                          child: isDrawerExpanded ? DrawerSummaryPage(currentGame: currentGame) : DrawerPreviewCard(currentGame: currentGame)
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ) : const LocationDisabledCard()
    );
  }
}


class CirclePainter extends CustomPainter {
  final double radius;

  CirclePainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red // Set the color of the circle here
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0; // Set the width of the circle's outline here

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}