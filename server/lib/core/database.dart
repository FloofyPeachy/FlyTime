import 'jdb.dart';

class UserDatabase {
  static JsonDatabase<User> users = JsonDatabase<User>("users.json", User.fromJson, (a) => a.toJson());
}

class User {
  String id;
  String email;
  DateTime createdAt;
  String jwt;

  List<String> fcmTokens;

  User({
    required this.id,
    required this.jwt,
    required this.email,
    required this.createdAt,
    required this.fcmTokens
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      jwt: json['jwt'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      fcmTokens: List<String>.from(json['fcmTokens']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'jwt': jwt,
    'createdAt': createdAt.toIso8601String(),
    'fcmTokens': fcmTokens,
  };

}

class OAuthAccount {

}
class OAuthDatabase {

}