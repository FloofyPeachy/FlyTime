import 'dart:convert';
import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:server/net/events.dart';
import 'package:server/core/util.dart';
import '../core/const.dart';
import '../core/logging.dart';
import '../core/model.dart';

class StaticData {
  //VATSIM data from VatGlasses.
  //A big class with data in it!

  Map<String, FlightInfoRegion> firs = {};
  static List<ControlledAirspace> airspaces = [];
  static List<ControlledAirport> airports = [];
  static Map<String, String> freqToName = {};

  static Future<void> init() async {
    sLogger.i("staticdata::Initializing static data...");
    await downloadData();
    await processAirspaceData();
    sLogger.i("staticdata::\x1B[32mStatic data ready!");
  }

  static Future<void> downloadData() async {
    sLogger.i("staticdata::Downloading VATGlasses data...");

    var shell = Shell();
   // await shell.run("rm -rf vatglasses-data");
   // await shell.run("git clone https://github.com/lennycolton/vatglasses-data");

    sLogger.i("staticdata::\x1B[32mStatic data downloaded!");
  }

  static Future<void> processAirspaceData() async {
    sLogger.i("staticdata::Processing VATGlasses data...");
    Directory dir = Directory("vatglasses-data/data");

    List<FileSystemEntity> entities = dir.listSync();

    for (FileSystemEntity entity in entities) {
      await processAirspaces(entity.path);
    }
    sLogger.i(
      "staticdata::\x1B[32mProcessed ${airspaces.length} airspaces and ${airports.length} airports",
    );
  }

  static Future<void> processAirspaces(String path) async {
    //if its a directory, do the directory stuff. if not, its a regular file with both in it.
    Map<String, dynamic> positionsJson = {};
    Map<String, dynamic> airportsJson = {};

    if ((await FileSystemEntity.type(path)) == FileSystemEntityType.directory) {
      airportsJson =
          (jsonDecode(await File("$path/airspace.json").readAsString())
              as Map<String, dynamic>)['airports'];
      positionsJson = jsonDecode(
        await File("$path/positions.json").readAsString(),
      )['positions'];
    } else {
      Map<String, dynamic> data = jsonDecode(await File(path).readAsString());

      positionsJson = data['positions']!;
      airportsJson = data['airports']!;
    }

    List<ControlledAirport> airports2 = [];
    Map<String, ControlledAirspace> spaces = {};
    Map<String, Frequency> allFreqs = {};

    airportsJson.forEach((k, v) {
      airports2.add(
        ControlledAirport(
          v['pre'] != null ? v['pre'][0] : k,
          k,
          v['callsign'],
          [],
        ),
      );
    });

    positionsJson.forEach((k, v1) {
      Map<String, dynamic> v = v1 as Map<String, dynamic>;
      if (spaces.containsKey(v['callsign'])) return;

      List<Map<String, dynamic>> callsignDuplicates = [];
      for (Map<String, dynamic> position in positionsJson.values) {
        if (k == "") {

        }
        if (position['callsign'] == v['callsign']) {
          if (v['frequency'] != null)  callsignDuplicates.add(position);

        }
      }

      if (v['callsign'] == "Los Angeles Center") {
        print("SFO!!");
      }
      List<String> removed = removeDuplicates(callsignDuplicates
          .map((x) => x['pre'] ?? ["rdkfhdfkjgdfg"])
          .expand((item) => item)
          .cast<String>()
          .toList());
      spaces[v['callsign'] ?? k] =
          ControlledAirspace(
            name: k,
            prefix: v['pre'] == null ? [v['name']] :  (removed.isEmpty ? List.from(v['pre']) : removed),
            callsign: v['callsign'] ?? k,
            fir: "f",
            type: FacilityType.values.firstWhere(
              (element) => element.internalName == v['type'],
            ),
            frequencies: callsignDuplicates.map((x) => x['frequency'] == null ? "" : x['frequency'] as String).toList(),
            airports: airports2,
          );
    });

    airspaces.addAll(spaces.values);
    airports.addAll(airports2);
  }

  static String conToFriendly(
    String frequency,
    String name,
    FacilityType type,
  ) {
    if (!freqToName.containsKey(frequency)) {
      if (type == FacilityType.center || type == FacilityType.radio || type == FacilityType.approach) {
        List<ControlledAirspace> possibleSpaces = airspaces
            .where((x) => x.prefix.contains(name.split("_")[0]))
            .where((x) => x.type == type)
            .toList();
        if (possibleSpaces.isNotEmpty) {
          return possibleSpaces[0].callsign;
        }
      } else {
        //Might be an airport.
        String splitName = name.split("_")[0];
        //String testName = splitName.length == 4? splitName.substring(1, 4) : splitName;
        String testName = splitName.length == 4? splitName.substring(1, 4) : splitName;
        List<ControlledAirport> possiblePorts = airports
            .where((x) => x.name.length == 4 ? x.name.substring(1, 4) == testName : x.name == testName)
            .toList();

        if (possiblePorts.isEmpty) {
          //Hmm. Test again with the entire name.
          possiblePorts = airports
              .where((x) => x.fullName == splitName)
              .toList();
          if (possiblePorts.isEmpty) return name;
        }

        return possiblePorts[0].friendlyName;
      }

    }
    return name;
  }
}

class VatsimData {
  static List<OnlineController> allOnlineControllers = [];
  static List<Event> allEvents = [];
  static List<Event> activeEvents = [];
  static Future<void> init() async {
    sLogger.i("livedata::Initializing VATSIM live data..");
    EventPublisher.init();

    //Get events too.
    var eventsRq = await client.get(
      Uri.parse('https://my.vatsim.net/api/v2/events/latest'),
    );

    if (eventsRq.statusCode == 200) {
      allEvents = (jsonDecode(eventsRq.body)['data'] as List<dynamic>).map((e) => Event.fromJson(e)).toList();
      sLogger.i("livedata::\x1B[32mLoaded ${allEvents.length} events");
    }



  }

  static Future<void> update() async {
    sLogger.i("livedata::Refreshing VATSIM data..");

    try {

      for (var element in allEvents) {
        if (element.startTime.isBefore(DateTime.now()) && element.endTime.isAfter(DateTime.now())) {
          sLogger.i("livedata::Event active: ${element.name}");
          if (!activeEvents.contains(element)) {
            activeEvents.add(element);
           // EventPublisher.notifyEvent(element);
          }

        }
      }

      var response = await client.get(
        Uri.parse('https://data.vatsim.net/v3/vatsim-data.json'),
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> vatsimData = jsonDecode(response.body);

        List<OnlineController> controllers1 = [];
        for (var value in (vatsimData['controllers'] as List<dynamic>)) {
          if (value['frequency'] == "199.998") continue;
          try {
            List<String> splitName = value['callsign'].split("_");
            OnlineController controller = OnlineController.fromJson(value);

            for (var element in activeEvents) {
              if (element.airports.where((x) => x.contains(splitName[0])).isNotEmpty) {
                controller.activeEventId = element.id;
                //EventPublisher.notifyEvent(element);
              }
            }
            controllers1.add(controller);
          } on Exception catch (e) {
            sLogger.e(e);
          }
        }

        controllers1.sort((a, b) {
          int typeCompare = Enum.compareByIndex(b.type, a.type);
          if (typeCompare != 0) return typeCompare;
          return a.friendlyName.compareTo(b.friendlyName);
        });
        List<OnlineController> addedControllers = controllers1
            .where((item) => !allOnlineControllers.contains(item))
            .toList();
        allOnlineControllers = controllers1;

        sLogger.i(
          "${allOnlineControllers.length} online, ${addedControllers.length} added",
        );
        if (addedControllers.isNotEmpty) {
          EventPublisher.notify(addedControllers);
        }

      } else {
        sLogger.e('livedata::Request failed with status: ${response.statusCode}.');
      }

      //Oh also check the events.

    } on Exception catch (e) {
      sLogger.e("livedata::Couldn't update dynamic data: ");
      sLogger.e(e);
    }
  }
}
