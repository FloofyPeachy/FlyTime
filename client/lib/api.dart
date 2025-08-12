import 'dart:convert';
import 'dart:io';

import 'package:client/core/prefs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'core/model.dart';

class FlyTimeAPI {
  static const String BASE_URL = 'http://10.0.0.30:1337/';
  static var client = http.Client();



  static Future<void> loadSubscriptions() async {
    var response = await client.get(
      headers: {
        'Authorization': '${Preferences.userToken}'
      },
        Uri.parse('${BASE_URL}get_subs'));
    Map<String, dynamic> data = jsonDecode(response.body);
    Preferences.subscription = List<SubscriptionPref>.from(jsonDecode(response.body)['regions'].map((model) => SubscriptionPref.fromJson(model)));
    if (response.statusCode == 200) {
     print(data);
    }
  }

  static Future<bool> updateSubscription() async {
    String? firebaseId = "no_fcm";
    if (!Platform.isLinux && !Platform.isWindows) firebaseId = await FirebaseMessaging.instance.getToken();

    if (firebaseId == null) throw Exception("FirebaseID is null for some reason..");

    List< Map<String, dynamic>> regions = [];
    for (var value in Preferences.subscription) {
      regions.add({
        'prefix' : value.prefix,
        'types' : value.types
      });
    }

    Map<String, dynamic> subscription = {
      'firebaseId': firebaseId,
      'regions' : regions
  };


    var response = await client.post(headers: Preferences.userToken == "" ? {} : {
      'Authorization': Preferences.userToken
    },
        Uri.parse('${BASE_URL}subscribe'),
    body: jsonEncode(subscription));



    return true;
  }


  static Future<List<OnlineController>> getOnline(bool all) async {
    try {
      print('FlyTimeAPI.getOnline called');
      List<String> regions = [];
      for (var value in Preferences.subscription) {
        regions.add(value.prefix);
      }
      if (regions.isEmpty) all = true;
      var response = await client.get(
        Uri.parse('${BASE_URL}online/${all ? 'all' : regions.join(',')}'),

        headers: {
          'Content-Type': 'application/json'
        }
      );

      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => OnlineController.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load online controllers ${response.statusCode} ${response.body}');
      }
    } on Exception catch (e) {
      throw Exception('Failed to load online controllers ${e}');
    }
  }


  static Future<Event> getActiveEvent(int id) async {
    try {
      var response = await client.get(Uri.parse('${BASE_URL}get_active_event/$id'));
      if (response.statusCode == 200) {
        return Event.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load event ${response.statusCode} ${response.body}');
      }
    } on Exception catch (e) {
      throw Exception('Failed to load event ${e}');
    }
  }

  static Future<List<ControlledAirspace>> searchAirspaces(String query) async {
    try {
      var response = await client.get(Uri.parse('${BASE_URL}search_airspace/$query'));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => ControlledAirspace.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load airspace ${response.statusCode} ${response.body}');
      }
    } on Exception catch (e) {
      throw Exception('Failed to load airspace ${e}');
    }
  }

  static Future<List<ControlledAirport>> searchAirports(String query) async {
    try {
      var response = await client.get(Uri.parse('${BASE_URL}search_airport/$query'));
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List).map((e) => ControlledAirport.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load airport ${response.statusCode} ${response.body}');
      }
    } on Exception catch (e) {
      throw Exception('Failed to load airport ${e}');
    }
  }


  static Future<bool> vatsimLogin() async {
    try {
      final client = http.Client();
      var request = http.Request("POST", Uri.parse('${BASE_URL}vatsim_login'));
      final response = await client.send(request);
      print("dfgdfgdf");
      try {
        // Listen to the stream of bytes and decode as UTF-8
        final stream = response.stream.transform(utf8.decoder);

        await for (var chunk in stream) {
          print('Received chunk: $chunk');
          Map<String, dynamic> data = jsonDecode(chunk);
          if (data.containsKey("url")) {
            await launchUrl(Uri.parse(data['url']));
          } else {
            Preferences.userToken = data['jwt'];
            await Preferences.saveSecret();
            client.close();
            return true;
          }
        }

      } finally {
        client.close();
      }
      return true;

/*
      if (response.statusCode == 200) {
        return Uri.parse(jsonDecode(response.body)['url']);
      } else {
        throw Exception('Failed to load vatsim login ${response.statusCode} ${response.body}');
      }*/
    } on Exception catch (e) {
      throw Exception('Failed to load vatsim login ${e}');
    }
  }
}