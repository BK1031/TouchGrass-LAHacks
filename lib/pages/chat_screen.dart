import 'dart:async';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter/cupertino.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Chat'),
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text('Your Chat UI Goes Here'),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: CupertinoTextField(
                controller: _textController,
                placeholder: 'Type your message here',
                onSubmitted: (_) {
                  // Handle message submission
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
