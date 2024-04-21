import 'dart:async';

import 'package:battleship_lahacks/models/missile.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:flutter/material.dart';

class MissileCountdownText extends StatefulWidget {
  final Missile missile;
  final TextStyle style;
  const MissileCountdownText({super.key, required this.missile, required this.style});

  @override
  State<MissileCountdownText> createState() => _MissileCountdownTextState();
}

class _MissileCountdownTextState extends State<MissileCountdownText> {
  late Timer countdownTimer;
  Duration difference = const Duration();

  @override
  void initState() {
    super.initState();
    DateTime time = DateTime.now();
    if (widget.missile.status == "DEPLOYED") {
      time = widget.missile.launchTime.toLocal().add(Duration(seconds: widget.missile.detonationTime));
    } else if (widget.missile.status == "COOLDOWN") {
      time = widget.missile.launchTime.toLocal().add(Duration(seconds: DEFAULT_COOLDOWN));
    }
    countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (DateTime.now().isAfter(time)) {
          difference = Duration.zero;
        } else {
          difference = time.difference(DateTime.now());
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    countdownTimer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
        "${difference.inMinutes.remainder(60)}m ${difference.inSeconds.remainder(60)}s",
        style: widget.style
    );
  }
}

