import 'dart:io';

import 'package:dart_firebase_admin/messaging.dart';
import 'package:server/core/model.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:server/data/subscriptions.dart';

import '../core/logging.dart';

class EventPublisher {
  static late FirebaseAdminApp adminApp;

  static void init() {
    adminApp = FirebaseAdminApp.initializeApp(
      'flytime-ef2f6',
      // This will obtain authentication information from the environment
      Credential.fromServiceAccount(File('service-account.json')),
    );
  }

  static Future<void> notify(List<OnlineController> controllers) async {
    for (var subscription in Subscriptions.subscriptions) {
      List<OnlineController> subscribed = [];
      for (var controller in controllers) {
        for (var region in subscription.regions) {
          if (controller.callsign.startsWith(region.prefix) &&
             (region.types.contains(controller.type) || region.types.contains(FacilityType.all) && subscription.firebaseId != "no_fcm")) {
            subscribed.add(controller);
            break;
          }
        }
      }
      if (subscribed.isNotEmpty) sendNotification(subscription, subscribed);
    }
  }

  static void sendNotification(
    SubscriptionFreq device,
    List<OnlineController> controllers,
  ) {
    sLogger.i("events::Notifying ${device.firebaseId} about new ATC");
    String titleText = controllers.length > 1 ? "Multiple ATC Online" : controllers[0].friendlyName;
    StringBuffer bodyText = StringBuffer();

    if (controllers.length > 1) {
      for (int i = 0; i < controllers.length; i++) {
        OnlineController controller = controllers[i];
        if (i == controllers.length - 1) {
          bodyText.write("and ${controller.callsign} are online! Time to fly!");
        } else {
          bodyText.write("${controller.callsign}, ");
        }

      }
    } else {
      bodyText.write("${controllers[0].callsign} is now online! Time to fly!");
    }

    final messaging = Messaging(adminApp);
    messaging.send(
      TokenMessage(
        // The token of the targeted device.
        // This token can be obtain by using FlutterFire's firebase_messaging:
        // https://pub.dev/documentation/firebase_messaging/latest/firebase_messaging/FirebaseMessaging/getToken.html
        token: device.firebaseId,

        notification: Notification(
          // The content of the notification
          title: titleText,
          body: bodyText.toString(),
        ),
        android: AndroidConfig(
          notification: AndroidNotification(
            title: titleText,
            body: bodyText.toString(),
            sound: "ding.mp3",
            channelId: "message_channel",
            priority: AndroidNotificationPriority.max,
          ),
        ),
      ),
    );
  }
}

class SubscriptionRegion {
  String prefix;
  List<FacilityType> types;

  SubscriptionRegion(this.prefix, this.types);

  SubscriptionRegion.fromJson(Map<String, dynamic> json)
    : prefix = json['prefix'],
      types = List<FacilityType>.from(
        json['types'].map((model) =>  FacilityType.values.firstWhere((x) => x.internalName == model)),
      );
  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'types': types,
  };
}

class SubscriptionFreq {
  List<SubscriptionRegion> regions;
  String? vatsimId;
  String firebaseId;

  SubscriptionFreq(this.regions, this.firebaseId, this.vatsimId);

  SubscriptionFreq.fromJson(Map<String, dynamic> json)
    : regions = List<SubscriptionRegion>.from(
        json['regions'].map((model) => SubscriptionRegion.fromJson(model)),
      ),
      firebaseId = json['firebaseId'],
      vatsimId = json['vatsimId'];

  Map<String, dynamic> toJson() => {
    'regions': regions,
    'firebaseId': firebaseId,
    'vatsimId': vatsimId
  };
}
