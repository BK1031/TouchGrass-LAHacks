class Game {
  String id = "";
  String name = "";
  String adminID = "";
  String joinCode = "";
  DateTime startTime = DateTime.now().toUtc();
  DateTime endTime = DateTime.now().toUtc();
  GameSettings settings = GameSettings();

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
}

class GameSettings {
  List<CeasefireHour> ceasefireHours = [];
  int stepGoal = 0;

  GameSettings();

  GameSettings.fromJson(Map<String, dynamic> json) {
    for (int i = 0; i < json["ceasefire_hours"]; i++) {
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