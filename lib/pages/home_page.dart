import 'dart:async';
import 'dart:math';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:battleship_lahacks/widgets/location_disabled_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
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
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = currentLocation;
      });
      log("Current Location: ${currentPosition!.latitude}, ${currentPosition!.longitude}");
      FirebaseFirestore.instance.collection("users/${currentUser.id}/location_history").add({
        "lat": currentPosition!.latitude,
        "long": currentPosition!.longitude,
        "timestamp": DateTime.now()
      });
    });
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

                        },
                        child: Row(
                          children: [
                            ClipRRect(
                              child: Image.network(currentUser.profilePictureURL, height: 40),
                              borderRadius: BorderRadius.circular(512),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 8, right: 16),
                              child: Text("832 pts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(512)),
                      child: InkWell(
                        onTap: () {

                        },
                        child: Padding(
                          padding: EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8),
                          child: Row(
                            children: [
                              Text("Bharat's Game", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                              Padding(padding: EdgeInsets.all(2)),
                              Icon(Icons.keyboard_arrow_down_rounded)
                            ],
                          ),
                        ),
                      ),
                    )
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
