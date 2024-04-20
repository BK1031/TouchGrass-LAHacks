class Game {
  String id = "";
  String name = "";
  String adminID = "";
  String joinCode = "";
  DateTime startTime = DateTime.now().toUtc();
  DateTime endTime = DateTime.now().toUtc();

  Game();

  Game.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    name = json["name"] ?? "";
    adminID = json["admin_id"] ?? "";
    joinCode = json["join_code"] ?? "";
    startTime = DateTime.tryParse(json["start_time"]) ?? DateTime.now().toUtc();
    endTime = DateTime.tryParse(json["end_time"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "admin_id": adminID,
      "join_code": joinCode,
      "start_time": startTime.toIso8601String(),
      "end_time": endTime.toIso8601String(),
    };
  }
}

class GameSettings {

}