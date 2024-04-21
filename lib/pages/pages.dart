import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';


double crosshairSize = 125;
//double AOE_Radius = 50;

bool targeting = false;
LatLng? targetPosition;
String bountyString='Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words.';
String activityString='Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words. Many Words.';

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
            icon: Icon(CupertinoIcons.money_dollar),
            label: 'Bounty',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_solid),
            label: 'Profile',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(CupertinoIcons.tree),
          //   label: 'Explorer',
          // ),
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
        return BountyPage(); // Return the ChatPage widget when index is 1
      case 2:
        return ProfilePage(); // Return the ProfilePage widget when index is 2
      case 3:
        return ExplorerPage(); // Return the ProfilePage widget when index is 2
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

  void _onMapClick(point, latLng) {
    if(!targeting)
        return;
    targetPosition=latLng;
    mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          latLng.latitude,
          latLng.longitude,
        ),
      ),
    );
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
            onMapClick: (point, latlng) => _onMapClick(point, latlng),
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
          Center(
            child: Column(
              children: [
                SizedBox(height: 740), // Empty container to create offset
                GestureDetector(
                  onTap: () {
                    setState(() {
                      targeting = true;
                    });
                    // Open weapons menu
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                    ),
                    child: Icon(
                      Icons.wifi_tethering,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: targeting ? // Check if targeting is true
            Image.asset(
              "images/Crosshair.png",
              width: crosshairSize, // Set the width to match the image size
              height: crosshairSize, // Set the height to match the image size
            ) : // If targeting is false, don't display the image
            SizedBox(), // Use SizedBox to occupy the space without displaying anything
          ),
          SizedBox(
            height: 720,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    targeting = false;
                  });
                },
                child: targeting
                    ? Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    "images/Launch.png",
                    width: 50,
                    height: 50,
                  ),
                )
                    : SizedBox(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BountyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,

        middle: Text(
          'Bounty',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            inherit: false,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 63),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center( // Centering the text vertically and horizontally
                  child: Text(
                    bountyString,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      inherit: false,
                    ),
                    overflow: TextOverflow.visible,
                    softWrap: true,
                  ),
                ),
              ),
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
    int num = 4835;
    int num2 = 485;
    int num1 = 4855;
    int num3 = 45;
    int num4 = 355;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
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
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Container(
            height: 100, // Adjust the height of the rectangles as needed
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center( // Centering the text vertically and horizontally
              child: Text(
                '$num Points',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  inherit: false,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 100, // Adjust the height of the rectangles as needed
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center( // Centering the text vertically and horizontally
                    child: Text(
                      '$num1 Steps',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        inherit: false,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 20), // Add space between the boxes
              Expanded(
                child: Container(
                  height: 100, // Adjust the height of the rectangles as needed
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center( // Centering the text vertically and horizontally
                    child: Text(
                      '$num2 Miles',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        inherit: false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(//5
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Container(
            height: 170, // Adjust the height of the rectangles as needed
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.18),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [],
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity, // Ensure the graph takes full width of the container
                height: 150, // Adjust the height of the graph as needed
                child: LineChart(
                  sampleData1(), // Use the example data method here
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Container(
            height: 300, // Adjust the height of the rectangles as needed
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Center( // Centering the text vertically and horizontally
                child: Text(
                  activityString,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    inherit: false,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

LineChartData sampleData1() {
  return LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(show: false),
    borderData: FlBorderData(show: false),
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 10,
    lineBarsData: [
      LineChartBarData(
        spots: [
          FlSpot(0, 3),
          FlSpot(1, 4),
          FlSpot(2, 3.5),
          FlSpot(3, 5),
          FlSpot(4, 4.5),
          FlSpot(5, 6),
          FlSpot(6, 8),
        ],
        isCurved: true,
        //colors: [Colors.blue],
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
      ),
    ],
  );
}




class ExplorerPage extends StatefulWidget {
  const ExplorerPage({Key? key}) : super(key: key);

  @override
  _ExplorerPageState createState() => _ExplorerPageState();
}

LatLng target = LatLng(34.412278, -119.847787);

class _ExplorerPageState extends State<ExplorerPage> {
  MapboxMapController? mapController;

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
  }

  void updateTarget(LatLng pos) {
    target = pos;

    mapController!.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(
          pos.latitude,
          pos.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            accessToken: 'YOUR_ACCESS_TOKEN',
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(34.412278, -119.847787),
              zoom: 14.0,
            ),
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
                          target.latitude,
                          target.longitude,
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