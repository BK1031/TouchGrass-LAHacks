import 'dart:async';

import 'package:flutter/material.dart';

class CountdownText extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle style;

  const CountdownText({required this.dateTime, required this.style});

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {

  late Timer countdownTimer;
  Duration difference = const Duration();

  @override
  void initState() {
    super.initState();
    countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        if (DateTime.now().isAfter(widget.dateTime.toLocal())) {
          difference = DateTime.now().difference(widget.dateTime.toLocal());
        } else {
          difference = widget.dateTime.toLocal().difference(DateTime.now());
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
      "${difference.inDays}d ${difference.inHours.remainder(24)}h ${difference.inMinutes.remainder(60)}m ${difference.inSeconds.remainder(60)}s",
        style: widget.style
    );
  }
}

