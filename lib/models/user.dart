import 'package:battleship_lahacks/utils/logger.dart';

class User {
  String id = "";
  String username = "";
  String firstName = "";
  String lastName = "";
  String email = "";
  String profilePictureURL = "https://api.dicebear.com/8.x/notionists-neutral/png?seed=Leo&backgroundColor=c0aede,b6e3f4";
  String status = "";

  User();

  User.fromJson(Map<String, dynamic> json) {
    id = json["id"] ?? "";
    username = json["username"] ?? "";
    firstName = json["first_name"] ?? "";
    lastName = json["last_name"] ?? "";
    email = json["email"] ?? "";
    profilePictureURL = json["profile_picture_url"] ?? "";
    status = json["status"] ?? "";
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "username": username,
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "profile_picture_url": profilePictureURL,
      "status": status,
    };
  }

  void debugPrint() {
    log("====== USER DEBUG INFO ======");
    log("FIRST NAME: $firstName");
    log("LAST NAME: $lastName");
    log("EMAIL: $email");
    log("====== =============== ======");
  }
}