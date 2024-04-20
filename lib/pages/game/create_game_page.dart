import 'dart:convert';
import 'dart:math';

import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/models/player.dart';
import 'package:battleship_lahacks/utils/alert_service.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:battleship_lahacks/utils/theme.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  bool showCeasefireAdd = false;
  DateTime ceasefireStart = DateTime.now().toUtc();
  DateTime ceasefireEnd = DateTime.now().toUtc();

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

  Future<void> createGame() async {
    if (game.name == "") {
      game.name = "${currentUser.firstName}'s Game";
    }
    game.adminID = currentUser.id;
    DocumentReference ref = await FirebaseFirestore.instance.collection("games").add(game.toJson());
    game.id = ref.id;
    FirebaseFirestore.instance.doc("games/${game.id}").update({"id": game.id});
    Player me = Player();
    me.id = currentUser.id;
    me.points = STARTING_POINTS;
    game.players.add(me);
    FirebaseFirestore.instance.doc("games/${game.id}/players/${currentUser.id}").set(me.toJson());
    setState(() {
      currentGame = game;
      joinedGames.add(game);
    });
    router.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create a game"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
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
                    Text("Join Code: ${game.joinCode}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: game.joinCode));
                        AlertService.showInfoSnackbar(context, "Copied join code to clipboard!");
                      },
                      icon: const Icon(Icons.copy),
                    )
                  ],
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.all(4)),
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
                          game.startTime = result.toUtc();
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
            const Padding(padding: EdgeInsets.all(4)),
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
                            game.endTime = result.toUtc();
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
            const Padding(padding: EdgeInsets.all(8)),
            ExpansionTile(
              title: Text("Advanced Options"),
              children: [
                Row(
                  children: [
                    const Text("Minimum Daily Steps", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                    const Padding(padding: EdgeInsets.all(2)),
                    Expanded(
                      child: TextField(
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0"
                        ),
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                        onChanged: (input) {
                          game.settings.stepGoal = int.tryParse(input) ?? 0;
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Ceasefire Hours", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                    Visibility(
                      visible: !showCeasefireAdd,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            showCeasefireAdd = true;
                          });
                        },
                        icon: Icon(Icons.add_circle),
                      ),
                    )
                  ],
                ),
                Column(
                  children: game.settings.ceasefireHours.map((e) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(DateFormat().add_jm().format(e.start.toLocal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                              )
                          ),
                          const Text("to", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                          Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(DateFormat().add_jm().format(e.end.toLocal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                              )
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            game.settings.ceasefireHours.remove(e);
                          });
                        },
                        icon: Icon(Icons.cancel),
                      )
                    ],
                  )).toList(),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: showCeasefireAdd ? 100 : 0,
                  child: showCeasefireAdd ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // const Text("Enter Range", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                          Row(
                            children: [
                              Card(
                                child: InkWell(
                                  onTap: () async {
                                    final result = await showBoardDateTimePicker(
                                        context: context,
                                        pickerType: DateTimePickerType.time,
                                        options: const BoardDateTimeOptions(activeTextColor: Colors.black)
                                    );
                                    if (result != null) {
                                      setState(() {
                                        ceasefireStart = result.toUtc();
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(DateFormat().add_jm().format(ceasefireStart.toLocal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                                  ),
                                )
                              ),
                              const Text("to", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                              Card(
                                  child: InkWell(
                                    onTap: () async {
                                      final result = await showBoardDateTimePicker(
                                          context: context,
                                          pickerType: DateTimePickerType.time,
                                          options: const BoardDateTimeOptions(activeTextColor: Colors.black)
                                      );
                                      if (result != null) {
                                        setState(() {
                                          ceasefireEnd = result.toUtc();
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(DateFormat().add_jm().format(ceasefireEnd.toLocal()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),),
                                    ),
                                  )
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    CeasefireHour hour = CeasefireHour();
                                    hour.start = ceasefireStart;
                                    hour.end = ceasefireEnd;
                                    game.settings.ceasefireHours.add(hour);
                                    showCeasefireAdd = false;
                                  });
                                },
                                icon: Icon(Icons.check_circle),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    showCeasefireAdd = false;
                                  });
                                },
                                icon: Icon(Icons.cancel),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ) : Container(),
                )
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            SizedBox(
              height: 50.0,
              width: double.infinity,
              child: CupertinoButton(
                color: ACCENT_COLOR,
                borderRadius: BorderRadius.circular(16),
                onPressed: () {
                  createGame();
                },
                child: const Text("Create Game", style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
