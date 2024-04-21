import 'package:battleship_lahacks/models/player.dart';
import 'package:battleship_lahacks/utils/config.dart';
import 'package:flutter/material.dart';

class DrawerPreviewCard extends StatefulWidget {
  const DrawerPreviewCard({super.key});

  @override
  State<DrawerPreviewCard> createState() => _DrawerPreviewCardState();
}

class _DrawerPreviewCardState extends State<DrawerPreviewCard> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.keyboard_arrow_up_rounded, size: 40),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_rounded, size: 26,),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(currentGame.players.length.toString(), style: const TextStyle(fontSize: 18),),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.electric_bolt_rounded, size: 26,),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(currentGame.players.firstWhere((p) => p.id == currentUser.id, orElse: () => Player()).hits.toString(), style: const TextStyle(fontSize: 18),),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.numbers_rounded, size: 26,),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text(currentGame.players.firstWhere((p) => p.id == currentUser.id, orElse: () => Player()).attempts.toString(), style: const TextStyle(fontSize: 18),),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, size: 26,),
                  const Padding(padding: EdgeInsets.all(4)),
                  Text((currentGame.players.indexWhere((p) => p.id == currentUser.id) + 1).toString(), style: const TextStyle(fontSize: 18),),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
