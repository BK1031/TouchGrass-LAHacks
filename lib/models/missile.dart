class Missile {
  String id = "";
  String userID = "";
  String gameID = "";
  double targetLat = 0.0;
  double targetLong = 0.0;
  int detonationTime = 0;
  int radius = 0;
  DateTime sentTime = DateTime.now().toUtc();
  List<MissileHit> hits = [];

  Missile();

  Missile.fromJson(Map<String, dynamic> json) {
    id = json["ID"] ?? "";
    userID = json["UserID"] ?? "";
    gameID = json["GameID"] ?? "";
    targetLat = json["Targetlat"] ?? 0.0;
    targetLong = json["Targetlong"] ?? 0.0;
    detonationTime = json["Detonationtime"] ?? 0;
    radius = json["Radius"] ?? 0;
    sentTime = DateTime.tryParse(json["SentTime"]) ?? DateTime.now().toUtc();
    json["Hits"].keys.forEach((key) {
      hits.add(MissileHit.fromJson(json["Hits"][key]));
    });
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userID,
      "game_id": gameID,
      "target_lat": targetLat,
      "target_long": targetLong,
      "detonation_time": detonationTime,
      "radius": radius
    };
  }
}

class MissileHit {
  String userID = "";
  double contact_lat = 0.0;
  double contact_long = 0.0;
  int damage = 0;

  MissileHit();

  MissileHit.fromJson(Map<String, dynamic> json) {
    userID = json["userID"] ?? "";
    contact_lat = json["lat"] ?? 0;
    contact_lat = json["long"] ?? 0;
    damage = json["damage"] ?? 0;
  }

}