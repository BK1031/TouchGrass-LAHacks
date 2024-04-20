import 'package:battleship_lahacks/pages/home_page.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
    return const Scaffold(
        body: Center(
            child: Text("Unexpected error. See log for details.")));
  };

  await dotenv.load(fileName: ".env");
  MAPBOX_PUBLIC_TOKEN = dotenv.env['MAPBOX_PUBLIC_TOKEN']!;
  MAPBOX_ACCESS_TOKEN = dotenv.env['MAPBOX_ACCESS_TOKEN']!;

  prefs = await SharedPreferences.getInstance();

  // ROUTE DEFINITIONS
  router.define("/", handler: Handler(handlerFunc: (BuildContext? context, Map<String, dynamic>? params) {
    return const HomePage();
  }));

  runApp(MaterialApp(
    title: "Battleship",
    initialRoute: "/",
    onGenerateRoute: router.generator,
    theme: darkTheme,
    darkTheme: darkTheme,
    debugShowCheckedModeBanner: false,
    navigatorObservers: [
      routeObserver,
    ],
  ),);
}