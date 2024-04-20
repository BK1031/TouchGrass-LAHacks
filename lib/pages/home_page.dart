import 'dart:async';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart'; // Import Flutter's material library for GestureDetector
import 'package:fluro/fluro.dart';



double x = 20;
double y1 = 700;
double y2 = 650;

double crosshairSize = 125;
double AOE_Radius = 50;

bool targeting = true;


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
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        currentPosition = currentLocation;
      });
      log(
          "Current Location: ${currentPosition!.latitude}, ${currentPosition!.longitude}");
    });
  }

  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Battleship"),
      ),
      body: Stack(
        children: [
          MapboxMap(
            accessToken: kIsWeb ? MAPBOX_PUBLIC_TOKEN : MAPBOX_ACCESS_TOKEN,
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(34.412278, -119.847787),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            dragEnabled: true,
          ),
          Positioned(
            bottom: y1-6,
            right: x-7,
              child: Container(
                width: 45, // Set the width to your desired size
                height: 45, // Set the height to your desired size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
              ),
            ),
          ),
          Positioned(
            bottom: y2-6,
            right: x-7,
              child: Container(
                width: 45, // Set the width to your desired size
                height: 45, // Set the height to your desired size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              ),
            ),
          Positioned(
            bottom: y1,
            right: x,
            child: GestureDetector(
              onTap: () {
                router.navigateTo(context, "/chat", transition: TransitionType.fadeIn);
              },
              child: Container(
                width: 30, // Set the width to your desired size
                height: 30, // Set the height to your desired size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Image.asset(
                  "images/Chat.png",
                  width: 50, // Set the width to match the image size
                  height: 50, // Set the height to match the image size
                ),
              ),
            ),
          ),
          Positioned(
            bottom: y2+4,
            right: x+3,
            child: GestureDetector(
              onTap: () {
                mapController!.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      currentPosition!.latitude!,
                      currentPosition!.longitude!,
                    ),
                  ),
                );
              },
              child: Container(
                width: 23, // Set the width to your desired size
                height: 23, // Set the height to your desired size
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: Image.asset(
                  "images/Recenter.png",
                  width: 10, // Set the width to match the image size
                  height: 10, // Set the height to match the image size
                ),
              ),
            ),
          ),
          Center(
            child: targeting ? // Check if targeting is true
            CustomPaint(
              size: Size(crosshairSize, crosshairSize),
              painter: CirclePainter(radius: AOE_Radius),
            ): // If targeting is false, don't display the image
            SizedBox(), // Use SizedBox to occupy the space without displaying anything
          ),
          Center(
            child: targeting ? // Check if targeting is true
            Image.asset(
              "images/Crosshair.png",
              width: crosshairSize, // Set the width to match the image size
              height: crosshairSize, // Set the height to match the image size
            ) : // If targeting is false, don't display the image
            SizedBox(), // Use SizedBox to occupy the space without displaying anything
          )
        ],
      ),
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