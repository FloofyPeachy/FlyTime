import 'dart:convert';
import 'dart:io';

import '../net/events.dart';
import '../core/logging.dart';

class Subscriptions {
  static List<SubscriptionFreq> subscriptions = [];

  static Future<void> init() async {
    await loadSubscriptions();
  }

  static Future<void> loadSubscriptions() async {
    try {
      File subFile = File("subscriptions.json");
      if (!subFile.existsSync()) {
        subFile.createSync();
        saveSubscriptions();
        return;
      }

      subscriptions = List<SubscriptionFreq>.from(
        jsonDecode(
          subFile.readAsStringSync(),
        ).map((model) => SubscriptionFreq.fromJson(model)).toList(),
      );
      sLogger.i("subscriptions::\x1B[32mLoaded ${subscriptions.length} subscriptions ");
    } on Exception catch (e) {
      sLogger.e("Couldn't load subscriptions");
      sLogger.e(e);
    }
  }

  static void saveSubscriptions() {
    try {
      File subFile = File("subscriptions.json");
      if (!subFile.existsSync()) subFile.create();

      subFile.writeAsString(jsonEncode(subscriptions));
      sLogger.i("subscriptions::\x1B[32mSaved ${subscriptions.length} subscriptions to disk");
    } on Exception catch (e) {
      sLogger.e("Couldn't save subscriptions");
      sLogger.e(e);
    }
  }

  static void updateSubscription(SubscriptionFreq subscription) {
    //subscriptions.removeWhere((x) => x.firebaseId == subscription.firebaseId);
  //  subscriptions.removeWhere((x) => x.vatsimId == subscription.vatsimId);
    for (var x in subscriptions) {
      if (x.vatsimId == subscription.vatsimId) {
        if (x.firebaseId != "no_fcm" && subscription.firebaseId == "no_fcm") {
          subscription.firebaseId = x.firebaseId;
        }

      }
    }
    subscriptions.removeWhere((x) => x.firebaseId == subscription.firebaseId);
    subscriptions.removeWhere((x) => x.vatsimId == subscription.vatsimId);
    subscriptions.add(subscription);
    saveSubscriptions();
  }
}