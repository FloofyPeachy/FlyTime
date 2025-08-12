import 'dart:convert';

import 'package:client/core/model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static List<SubscriptionPref> subscription = [];
  static bool combineCenters = true;
  static bool combineAirports = true;
  static List<FacilityType> filter = List.of(FacilityType.values);
  static bool useCustomTitleBar = true;

  static String userToken = "";

  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await loadSecret();
    String? subs = prefs.getString("subs");
    if (subs != null && userToken == "") subscription = List<SubscriptionPref>.from(jsonDecode(subs).map((model) => SubscriptionPref.fromJson(model)));


    ;print("done!");
  }

  static Future<void> save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
   await prefs.setString("subs", jsonEncode(subscription));
  }

  static Future<void> loadSecret() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
      encryptedSharedPreferences: true,
    );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    if (await storage.containsKey(key: "userToken")) {
      userToken = (await storage.read(key: "userToken"))!;
    }
  }

  static Future<void> saveSecret() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
      encryptedSharedPreferences: true,
    );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    await storage.write(key: "userToken", value: userToken);
  }

}

class SubscriptionPref {
  final String prefix;
  final List<FacilityType> types;

  SubscriptionPref(this.prefix, this.types);

  factory SubscriptionPref.fromJson(Map<String, dynamic> json) {
    return SubscriptionPref(json['prefix'], List<FacilityType>.from(json['types'].map((model) =>  FacilityType.values.firstWhere((e) => e.internalName == model))));
  }

  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'types': types,
  };
}