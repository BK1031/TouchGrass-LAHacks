import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/material.dart'; // Import Flutter's material library for GestureDetector
import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import 'package:battleship_lahacks/utils/config.dart';

class Pages extends StatefulWidget {
  const Pages({Key? key}) : super(key: key);

  @override
  State<Pages> createState() => _PagesState();
}

class _PagesState extends State<Pages> {
  late TextEditingController _textController;
  late CupertinoTabController _tabController;
  int _selectedIndex = 0; // Store the index of the selected tab

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _tabController = CupertinoTabController(initialIndex: 0);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      controller: _tabController,
      tabBar: CupertinoTabBar(
        height: 60,
        activeColor: Colors.white,
        inactiveColor: Colors.white60,
        backgroundColor: Colors.black87, // Change the color here
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.text_bubble_fill),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_solid),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index when tab is tapped
          });
        },
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (BuildContext context) {
            return _buildPage(index); // Call a separate method to build the page
          },
        );
      },
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return MapPage(); // Return the MapPage widget when index is 0
      case 1:
        return ChatPage(); // Return the ChatPage widget when index is 1
      case 2:
        return ProfilePage(); // Return the ProfilePage widget when index is 2
      default:
        return Container(); // Return an empty container for unknown indexes
    }
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapboxMapController? mapController;
  Location location = Location();
  LocationData? currentPosition;

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
        // Show an alert if location service is not enabled
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Show an alert if location permission is not granted
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
      // appBar: AppBar(
      //   title: Text("Map",
      //     style: TextStyle(
      //       fontSize: 30,
      //       fontWeight: FontWeight.bold,
      //       color: Colors.white,
      //       inherit: false,
      //     ),
      //   ),
      // ),
      body: Stack(
        children: [
          MapboxMap(
            accessToken: 'YOUR_ACCESS_TOKEN',
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(34.412278, -119.847787),
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            dragEnabled: true,
          ),
          Positioned(
            bottom: 675,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
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
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.center_focus_strong,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black, // Set background color to white
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        middle: Text('Chat',
          style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          inherit: false,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 63, right: 8.0, left: 8.0), // Adjusted padding
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text('Chat Page'),
              ),
            ),
            CupertinoTextField(
              cursorOpacityAnimates: true,
              //padding: ,
              placeholder: 'Type your message here',
              style: TextStyle(color: Colors.white), // Change text color to white
              decoration: BoxDecoration(
                color: Colors.black, // Set background color to white
                border: Border.all(
                  color: Colors.white38, // Set border color to black
                  width: 1.0, // Set border width
                ),
                borderRadius: BorderRadius.circular(15.0), // Optional: Set border radius
              ),
              //padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Adjusted padding
              onSubmitted: (_) {
                // Handle message submission
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom:10),
          alignment: Alignment.center,
          child: Text(
            'Activity',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              inherit: false,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 10, // Change this to the desired number of rectangles
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Adjust padding as needed
                child: Container(
                  height: 100, // Adjust the height of the rectangles as needed
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.18),
                    borderRadius: BorderRadius.circular(10), // Set the radius for rounded corners
                    boxShadow: [],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


