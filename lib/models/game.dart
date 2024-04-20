import 'package:battleship_lahacks/models/player.dart';
import 'package:battleship_lahacks/utils/logger.dart';
import 'package:intl/intl.dart';

class Game {
  String id = "";
  String name = "";
  String adminID = "";
  String joinCode = "";
  DateTime startTime = DateTime.now().toUtc();
  DateTime endTime = DateTime.now().toUtc();
  GameSettings settings = GameSettings();
  List<Player> players = [];

  Game();

  Game.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    adminID = json["admin_id"] ?? "";
    joinCode = json["join_code"] ?? "";
    startTime = DateTime.tryParse(json["start_time"]) ?? DateTime.now().toUtc();
    endTime = DateTime.tryParse(json["end_time"]) ?? DateTime.now().toUtc();
    settings = GameSettings.fromJson(json["settings"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "admin_id": adminID,
      "join_code": joinCode,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
      "settings": settings.toJson()
    };
  }

  void debugPrint() {
    log("====== GAME DEBUG INFO ======");
    log("ID: $id – NAME: $name");
    log("${DateFormat().format(startTime.toLocal())} – ${DateFormat().format(endTime.toLocal())}");
    log("${players.length} PLAYERS");
    int maxPoints = 0;
    int leaderHits = 0;
    int leaderAttempts = 0;
    for (int i = 0; i < players.length; i++) {
      if (players[i].points > maxPoints) {
        maxPoints = players[i].points;
        leaderHits = players[i].hits;
        leaderAttempts = players[i].attempts;
      }
    }
    log("LEADER: $maxPoints POINTS, $leaderHits HITS, $leaderAttempts ATTEMPTS");
    log("====== =============== ======");
  }
}

class GameSettings {
  List<CeasefireHour> ceasefireHours = [];
  int stepGoal = 0;

  GameSettings();

  GameSettings.fromJson(Map<String, dynamic> json) {
    for (int i = 0; i < json["ceasefire_hours"].length; i++) {
      ceasefireHours.add(CeasefireHour.fromJson(json["ceasefire_hours"][i]));
    }
    stepGoal = json["step_goal"] ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      "ceasefire_hours": ceasefireHours.map((e) => e.toJson()).toList(),
      "step_goal": stepGoal,
    };
  }
}

class CeasefireHour {
  DateTime start = DateTime.now().toUtc();
  DateTime end = DateTime.now().toUtc();

  CeasefireHour();

  CeasefireHour.fromJson(Map<String, dynamic> json) {
    start = DateTime.tryParse(json["start"]) ?? DateTime.now().toUtc();
    end = DateTime.tryParse(json["end"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
    };
  }
}