class Player {
  String id = "";
  int points = 0;
  int hits = 0;
  int attempts = 0;
  DateTime joinDate = DateTime.now().toUtc();

  Player();

  Player.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    points = json["points"] ?? 0;
    hits = json["hits"] ?? 0;
    attempts = json["attempts"] ?? 0;
    joinDate = DateTime.tryParse(json["join_date"]) ?? DateTime.now().toUtc();
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "points": points,
      "hits": hits,
      "attempts": attempts,
      "join_date": joinDate.toIso8601String(),
    };
  }
}