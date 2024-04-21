import 'dart:async';

import 'package:battleship_lahacks/models/user.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AuthCheckerPage extends StatefulWidget {
  const AuthCheckerPage({super.key});

  @override
  State<AuthCheckerPage> createState() => _AuthCheckerPageState();
}

class _AuthCheckerPageState extends State<AuthCheckerPage> {

  double percent = 0.0;
  StreamSubscription<fb.User?>? _fbAuthSubscription;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  void checkAuthState() {
    Future.delayed(const Duration(milliseconds: 0), () {
      setState(() {percent = 1;});
    });
    _fbAuthSubscription = fb.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        // User not logged in
        router.navigateTo(context, "/register", transition: TransitionType.fadeIn, replace: true, clearStack: true);
      } else {
        // User is logged in
        log("[auth_checker_page] User session detected: ${user.uid}");
        await getUserInfo(user.uid);
        router.navigateTo(context, "/home", transition: TransitionType.fadeIn, replace: true, clearStack: true);
      }
    });
  }

  Future<void> getUserInfo(String id) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection("users").doc(id).get();
    if (snapshot.exists) {
      currentUser = User.fromJson(snapshot.data() as Map<String, dynamic>);
      currentUser.debugPrint();
    } else {
      await fb.FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularPercentIndicator(
                  radius: 42,
                  lineWidth: 7,
                  circularStrokeCap: CircularStrokeCap.round,
                  percent: 1,
                  // progressColor: sbNavy,
                  progressColor: Theme.of(context).cardColor,
                ),
                CircularPercentIndicator(
                  radius: 48,
                  lineWidth: 7,
                  circularStrokeCap: CircularStrokeCap.round,
                  percent: 1,
                  // progressColor: sbNavy,
                  progressColor: Theme.of(context).cardColor,
                ),
                CircularPercentIndicator(
                  radius: 45,
                  lineWidth: 7,
                  circularStrokeCap: CircularStrokeCap.round,
                  animateFromLastPercent: true,
                  animation: true,
                  percent: percent,
                  progressColor: ACCENT_COLOR,
                  // backgroundColor: sbNavy,
                  backgroundColor: Theme.of(context).cardColor,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
