import 'package:battleship_lahacks/models/game.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'countdown_text.dart';

class DrawerSummaryPage extends StatefulWidget {
  final Game currentGame;

  const DrawerSummaryPage({super.key, required this.currentGame});

  @override
  State<DrawerSummaryPage> createState() => _DrawerSummaryPageState();
}

class _DrawerSummaryPageState extends State<DrawerSummaryPage> {

  int index = 0;
  int attempts = 0;
  int hits = 0;

  bool geminiLoading = true;

  final PageController _pageController = PageController();

  String getAccuracy() {
    int i = widget.currentGame.players.indexWhere((p) => p.id == currentUser.id);
    if (i != -1 && widget.currentGame.players[i].attempts > 0) {
      setState(() {
        attempts = widget.currentGame.players[i].attempts;
        hits = widget.currentGame.players[i].hits;
      });
      return "${(hits / attempts * 100).floor()}%";
    }
    return "N/A";
  }

  Widget pageOne() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                        (widget.currentGame.players.indexWhere((p) => p.id == currentUser.id) + 1).toString(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center
                    ),
                    const Padding(padding: EdgeInsets.all(2)),
                    const Text("Leaderboard\nPosition", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                        getAccuracy(),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center
                    ),
                    const Padding(padding: EdgeInsets.all(2)),
                    const Text("EMP\nAccuracy", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                  ],
                ),
              )
            ],
          ),
          const Padding(padding: EdgeInsets.all(8)),
          Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                          hits.toString(),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center
                      ),
                      const Padding(padding: EdgeInsets.all(2)),
                      const Text("Successful\nStrikes", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                          attempts.toString(),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center
                      ),
                      const Padding(padding: EdgeInsets.all(2)),
                      const Text("Attempted\nStrikes", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                    ],
                  ),
                )
              ]
          ),
          const Padding(padding: EdgeInsets.all(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk_rounded, size: 32),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Daily Minimum Step Count", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
              Text(widget.currentGame.settings.stepGoal.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
            ],
          ),
          const Padding(padding: EdgeInsets.all(8)),
          ExpansionTile(
            collapsedIconColor: Colors.grey,
            childrenPadding: EdgeInsets.zero,
            tilePadding: EdgeInsets.zero,
            title: const Row(
              children: [
                Icon(Icons.pause_circle_filled_rounded, size: 32),
                Padding(padding: EdgeInsets.all(2)),
                Text("Ceasefire Times", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              ],
            ),
            children: widget.currentGame.settings.ceasefireHours.map((e) => Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
              ],
            )).toList(),
          ),
          DateTime.now().isBefore(widget.currentGame.startTime) ? Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Game starts in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                  CountdownText(dateTime: widget.currentGame.startTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                ],
              ),
            ),
          ) : DateTime.now().isAfter(widget.currentGame.startTime) && DateTime.now().isBefore(widget.currentGame.endTime) ? Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Game ends in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                  CountdownText(dateTime: widget.currentGame.endTime, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ),
          ) : Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Game ended on", style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                  Text(DateFormat().add_yMMMd().add_jm().format(widget.currentGame.endTime), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget pageTwo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
              "Leaderboard",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Card(
              child: Row(
                children: [
                  const Text("1st", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amberAccent),),
                  const Padding(padding: EdgeInsets.all(8)),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(512),
                      child: Image.network(currentUser.profilePictureURL, width: 64,)
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  Column(
                    children: [
                      Text("${currentUser.firstName} ${currentUser.lastName}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                      const Text("4 hits, 10 attempts", style: TextStyle(fontSize: 16),),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Card(
              child: Row(
                children: [
                  const Text("2nd", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white70),),
                  const Padding(padding: EdgeInsets.all(8)),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(512),
                      child: Image.network(currentUser.profilePictureURL, width: 64,)
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  Column(
                    children: [
                      Text("Alex Lopes", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                      const Text("2 hits, 12 attempts", style: TextStyle(fontSize: 16),),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Card(
              child: Row(
                children: [
                  const Text("3rd", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orangeAccent),),
                  const Padding(padding: EdgeInsets.all(8)),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(512),
                      child: Image.network(currentUser.profilePictureURL, width: 64,)
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  Column(
                    children: [
                      Text("Ryan Ngyuen", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                      const Text("2 hits, 19 attempts", style: TextStyle(fontSize: 16),),
                    ],
                  )
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Card(
              child: Row(
                children: [
                  const Text("4th", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,),),
                  const Padding(padding: EdgeInsets.all(8)),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(512),
                      child: Image.network(currentUser.profilePictureURL, width: 64,)
                  ),
                  const Padding(padding: EdgeInsets.all(8)),
                  Column(
                    children: [
                      Text("Nikunj Parasar", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
                      const Text("0 hits, 13 attempts", style: TextStyle(fontSize: 16),),
                    ],
                  )
                ],
              ),
            ),
          )
        ]
      ),
    );
  }

  Widget pageThree() {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Text(
              "Activity",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
          ),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.directions_walk_rounded, size: 32),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Daily Step Count", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
              Text("4,210", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shutter_speed_rounded, size: 32),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Distance Traveled", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
              Text("2.4 mi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
            ],
          ),
          Padding(padding: EdgeInsets.all(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_rounded, size: 32),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Average Heart Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
              Text("112 BPM", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))
            ],
          ),
          Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, size: 32),
                  Padding(padding: EdgeInsets.all(2)),
                  Text("Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ],
              ),
            ],
          ),
          Text(
            "Based on your location activity, it looks like you enjoyed playing tennis at the UCSB Tennis Courts today.  UCSB Campus Point is a beautiful location and a popular spot for UCSB students, faculty, staff and visitors.  I hope you had a chance to relax and take in the scenery as well!",
            style: TextStyle(fontSize: 16),
          )
        ],
      ),
    );
  }

  Widget pageFour() {
    DateTime bounty = DateTime.now().add(const Duration(days: 1, hours: 3, minutes: 21));
    return SingleChildScrollView(
      child: Column(
        children: [
          Text(
              "Daily Bounty",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
              "Solve the riddle to find your opp and get double the points!",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center
          ),
          Padding(padding: EdgeInsets.all(8)),
          geminiLoading ? CircularProgressIndicator() : Card(
            color: Colors.blueGrey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Can you hear the roar of the crowd, or is silence your study companion today? Are you catching rays by the iconic landmark, or lost in a world of knowledge?",
                style: TextStyle(fontSize: 16),
              ),
            )
          ),
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                const Text("Bounty expires in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
                CountdownText(dateTime: bounty, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        children: [
          const Icon(Icons.keyboard_arrow_down_rounded, size: 40),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() {
                  index = i;
                });
                if (index == 3) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    setState(() {
                      geminiLoading = false;
                    });
                  });
                }
              },
              children: [
                pageOne(),
                pageTwo(),
                pageThree(),
                pageFour(),
              ],
            )
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  color: index == 0 ? Colors.white : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.dashboard_rounded, color: index == 0 ? Colors.black : Colors.white),
                  ),
                ),
                Card(
                  color: index == 1 ? Colors.white : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.leaderboard_rounded, color: index == 1 ? Colors.black : Colors.white),
                  ),
                ),
                Card(
                  color: index == 2 ? Colors.white : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.directions_walk_rounded, color: index == 2 ? Colors.black : Colors.white),
                  ),
                ),
                Card(
                  color: index == 3 ? Colors.white : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.mail, color: index == 3 ? Colors.black : Colors.white),
                  ),
                ),
                Visibility(
                  visible: false,
                  child: Card(
                    color: index == 4 ? Colors.white : null,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.admin_panel_settings_rounded, color: index == 4 ? Colors.black : Colors.white),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
