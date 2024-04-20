import 'package:flutter/material.dart';

class LocationDisabledCard extends StatefulWidget {
  const LocationDisabledCard({super.key});

  @override
  State<LocationDisabledCard> createState() => _LocationDisabledCardState();
}

class _LocationDisabledCardState extends State<LocationDisabledCard> {

  bool showMessage = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      setState(() {
        showMessage = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return showMessage ? const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.gps_off_rounded, size: 75,),
          Padding(padding: EdgeInsets.all(8)),
          Text("Location Disabled", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
          Padding(padding: EdgeInsets.all(4)),
          Text("It looks like we can't access your location, please enable it in settings.", style: TextStyle(fontSize: 16), textAlign: TextAlign.center,),
        ],
      ),
    ) : const Center(
      child: CircularProgressIndicator(),
    );
  }
}
