class Missile {
  String id = "";
  String userID = "";
  String gameID = "";
  double targetLat = 0.0;
  double targetLong = 0.0;
  int detonationTime = 0;
  int damage = 0;
  int radius = 0;
  DateTime launchTime = DateTime.now().toUtc();
  String status = "";
  List<MissileHit> hits = [];

  Missile();

  Missile.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    userID = json["user_id"] ?? "";
    gameID = json["game_id"] ?? "";
    targetLat = json["target_lat"] ?? 0.0;
    targetLong = json["target_long"] ?? 0.0;
    detonationTime = json["detonation_time"] ?? 0;
    damage = json["damage"] ?? 0;
    radius = json["radius"] ?? 0;
    launchTime = DateTime.tryParse(json["launch_time"]) ?? DateTime.now().toUtc();
    status = json["status"] ?? "";
    for (int i = 0; i < json["hits"].length; i++) {
      hits.add(MissileHit.fromJson(json["hits"][i]));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userID,
      "game_id": gameID,
      "target_lat": targetLat,
      "target_long": targetLong,
      "detonation_time": detonationTime,
      "damage": damage,
      "radius": radius,
      "launch_time": launchTime.toIso8601String(),
      "status": "",
      "hits": hits
    };
  }
}

class MissileHit {
  String userID = "";
  double lat = 0.0;
  double long = 0.0;
  int distance = 0;
  int damage = 0;

  MissileHit();

  MissileHit.fromJson(Map<String, dynamic> json) {
    userID = json["user_id"] ?? "";
    lat = json["lat"] ?? 0.0;
    long = json["long"] ?? 0.0;
    distance = json["distance"] ?? 0;
    damage = json["damage"] ?? 0;
  }

}