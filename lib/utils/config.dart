import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/models/missile.dart';
import 'package:battleship_lahacks/models/user.dart';
import 'package:battleship_lahacks/models/version.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

final router = FluroRouter();
final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

var httpClient = http.Client();

late SharedPreferences prefs;

Version appVersion = Version("1.1.0+1");
Version stableVersion = Version("1.0.0+1");

// String LAUNCH_API_URL = "https://apihost.com/missile/launch";
String LAUNCH_API_URL = "https://rmetewm.com/missile/launch";

String MAPBOX_PUBLIC_TOKEN = "mapbox-public-token";
String MAPBOX_ACCESS_TOKEN = "mapbox-access-token";
String ONESIGNAL_TOKEN = "onesignal-token";

User currentUser = User();
LocationData? currentPosition;

Game currentGame = Game();
List<Game> joinedGames = [];
Missile lastMissile = Missile();

int STARTING_POINTS = 800;
int DEFAULT_DAMAGE = 400;
int DEFAULT_RADIUS = 50;
int DEFAULT_DETONATION_TIME = 300;
int DEFAULT_COOLDOWN = 60;