import 'dart:math';

import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/utils/alert_service.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({super.key});

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {

  Game game = Game();
  bool startTimeEdited = false;
  bool endTimeEdited = false;

  @override
  void initState() {
    super.initState();
    generateJoinCode();
  }

  void generateJoinCode() {
    setState(() {
      final letters = 'abcdefghijklmnopqrstuvwxyz';
      final random = Random();
      game.joinCode = String.fromCharCodes(Iterable.generate(6, (_) => letters.codeUnitAt(random.nextInt(letters.length)))).toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create a game"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "${currentUser.firstName}'s Game",
              ),
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
              onChanged: (input) {
                game.name = input;
              },
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Join Code: ${game.joinCode}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: game.joinCode));
                        AlertService.showInfoSnackbar(context, "Copied join code to clipboard!");
                      },
                      icon: Icon(Icons.copy),
                    )
                  ],
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Row(
              children: [
                const Text("Start Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await showBoardDateTimePicker(
                        context: context,
                        pickerType: DateTimePickerType.datetime,
                        options: const BoardDateTimeOptions(activeTextColor: Colors.black)
                      );
                      if (result != null) {
                        setState(() {
                          game.startTime = result;
                          startTimeEdited = true;
                        });
                      }
                    },
                    child: Text(
                      DateFormat().add_yMMMd().add_jm().format(game.startTime.toLocal()),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: startTimeEdited ? Colors.white : Colors.grey),
                      textAlign: TextAlign.end,
                    ),
                  )
                ),
              ],
            ),
            Padding(padding: EdgeInsets.all(4)),
            Row(
              children: [
                const Text("End Time", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                const Padding(padding: EdgeInsets.all(2)),
                Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showBoardDateTimePicker(
                            context: context,
                            pickerType: DateTimePickerType.datetime,
                            options: const BoardDateTimeOptions(activeTextColor: Colors.black)
                        );
                        if (result != null) {
                          setState(() {
                            game.endTime = result;
                            endTimeEdited = true;
                          });
                        }
                      },
                      child: Text(
                        DateFormat().add_yMMMd().add_jm().format(game.endTime.toLocal()),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: endTimeEdited ? Colors.white : Colors.grey),
                        textAlign: TextAlign.end,
                      ),
                    )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
