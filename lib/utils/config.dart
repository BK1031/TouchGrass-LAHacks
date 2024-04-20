import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

final router = FluroRouter();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

var httpClient = http.Client();

late SharedPreferences prefs;

String MAPBOX_PUBLIC_TOKEN = "mapbox-public-token";
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";

LocationData? currentPosition;