import 'dart:convert';

import 'package:flutter/material.dart';

class Organiser {
  final String? region;
  final String? division;
  final String? subdivision;
  final bool organisedByVatsim;

  Organiser(
    this.region,
    this.division,
    this.subdivision,
    this.organisedByVatsim,
  );

  factory Organiser.fromJson(Map<String, dynamic> json) {
    return Organiser(
      json['region'],
      json['division'],
      json['subdivision'],
      json['organised_by_vatsim'],
    );
  }
}

class Event {
  /*
  *  {
      "id": 1,
      "type": "Event",
      "name": "Example Event",
      "link": "https://my.vatsim.net/events/example-event",
      "organisers": [
        {
          "region": "AMAS",
          "division": "USA",
          "subdivision": null,
          "organised_by_vatsim": false
        }
      ],
      "airports": [
        {
          "icao": "KJFK"
        }
      ],
      "routes": [
        {
          "departure": "KJFK",
          "arrival": "KATL",
          "route": "RBV Q430 BYRDD J48 MOL FLASK OZZZI1"
        }
      ],
      "start_time": "1970-01-01T00:00:00.000000Z",
      "end_time": "1970-01-01T06:00:00.000000Z",
      "short_description": "Fly with us tonight!",
      "description": "Fly with us tonight!",
      "banner": "https://vatsim-my.nyc3.digitaloceanspaces.com/events/JpjoYKp6CRcz4V1wvdlMnQHiAtYOmT2p3DevEA7j.png"
    }*/
  final int id;
  final EventType type;
  final String name;
  final String link;
  final List<Organiser> organisers;
  final List<String> airports;
  final DateTime startTime;
  final DateTime endTime;
  final String shortDescription;
  final String description;
  final String banner;

  Event({
    required this.id,
    required this.type,
    required this.name,
    required this.link,
    required this.organisers,
    required this.airports,
    required this.startTime,
    required this.endTime,
    required this.shortDescription,
    required this.description,
    required this.banner,
  });

  factory Event.fromJson(Map<String, dynamic> json) {

    return Event(
      id: json['id'],
      type: EventType.values.firstWhere(
        (element) => element.name == json['type'],
        orElse: () => EventType.event,
      ),
      name: json['name'],
      link: json['link'],
      organisers: List<Organiser>.from(
        json['organisers'].map((e) => Organiser.fromJson(e)).toList(),
      ),
      airports: List<String>.from(json['airports']),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      shortDescription: json['short_description'],
      description: json['description'],
      banner: json['banner'],
    );
  }
}

enum EventType {
  event("Event"),
  controller_examination("Controller Examination"),
  vasops_event("VASOPS Event");

  final String name;

  const EventType(this.name);

  int toJson() => index;
}

class ControlledAirspace {
  final String name;
  final List<String> prefix;
  final String callsign;

  final String fir;
  final FacilityType type;

  final List<String>? frequencies;

  List<ControlledAirport> airports;

  ControlledAirspace({
    required this.name,
    required this.prefix,
    required this.callsign,
    required this.fir,
    required this.type,
    required this.frequencies,
    required this.airports,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'prefix': prefix,
    'callsign': callsign,
    'fir': fir,
    'type': type,
    'frequencies': frequencies,
    'airports': airports,
  };

  factory ControlledAirspace.fromJson(Map<String, dynamic> json) {
    FacilityType type = FacilityType.values.firstWhere(
      (element) => json['callsign'].endsWith(element.internalName),
      orElse: () => FacilityType.unknown,
    );
    return ControlledAirspace(
      name: json['name'],
      prefix:  List<String>.from(json['prefix'] as List),
      callsign: json['callsign'],
      fir: json['fir'],
      type: type,
      frequencies: List<String>.from(json['frequencies'] as List),
      airports: [],
    );
  }
}

class ControlledAirport {
  final String name;
  final String friendlyName;
  final String fullName;
  late List<(FacilityType, String)> frequency = [];

  ControlledAirport(
    this.name,
    this.fullName,
    this.friendlyName,
    this.frequency,
  );

  @override
  String toString() {
    return 'ControlledAirport{name: $name, friendlyName: $friendlyName, fullName: $fullName}';
  }

  ControlledAirport withFrequency(FacilityType type, String freq) {
    frequency.add((type, freq));
    return ControlledAirport(name, fullName, friendlyName, frequency);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControlledAirport &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          friendlyName == other.friendlyName &&
          fullName == other.fullName;

  @override
  int get hashCode => Object.hash(name, friendlyName, fullName);

  Map<String, dynamic> toJson() => {
    'name': name,
    'friendlyName': friendlyName,
    'fullName': fullName,
    'frequency': frequency,
  };

  factory ControlledAirport.fromJson(Map<String, dynamic> json) {
    return ControlledAirport(
      json['name'],
      json['fullName'],
      json['friendlyName'],
      [],
    );
  }
}

class OnlineControllerMerged {
  late List<String> callsign = [];
  late List<String> controllerName = [];
  late List<String> friendlyName = [];
  late List<FacilityType> type = [];
  late int? activeEventId;
  late List<String> frequency = [];
  late List<List<String>> atisString = [];
  late bool isAirport = false;
  OnlineControllerMerged(List<OnlineController> list, bool airport) {
    isAirport = airport;
    for (var element in list) {

        callsign.add(element.callsign);
        controllerName.add(element.controllerName);
        friendlyName.add(element.friendlyName);
        type.add(element.type);
        activeEventId = element.activeEventId ?? null;
        frequency.add(element.frequency);
        atisString.add(element.atisString);
      }

  }
}

class OnlineController {
  final String callsign;
  final String controllerName;
  final String friendlyName;
  final FacilityType type;
  final String frequency;
  final List<String> atisString;
  int? activeEventId;

  OnlineController({
    required this.callsign,
    required this.controllerName,
    required this.friendlyName,
    required this.type,
    required this.frequency,
    required this.atisString,
    this.activeEventId,
  });

  factory OnlineController.fromJson(Map<String, dynamic> json) {
    FacilityType type = FacilityType.values.firstWhere(
      (element) => json['callsign'].endsWith(element.internalName),
      orElse: () => FacilityType.unknown,
    );
    return OnlineController(
      callsign: json['callsign'],
      controllerName: json['controllerName'],
      friendlyName: json['friendlyName'],
      activeEventId: json['activeEventId'],
      type: type,
      frequency: json['frequency'],
      atisString: json['atisString'] == null
          ? []
          : List<String>.from(json['atisString'] as List),
    );
    ;
  }

  Map<String, dynamic> toJson() => {
    'callsign': callsign,
    'controllerName': controllerName,
    'friendlyName': friendlyName,
    'type': type,
    'frequency': frequency,
    'atisString': atisString,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnlineController &&
          runtimeType == other.runtimeType &&
          callsign == other.callsign &&
          controllerName == other.controllerName &&
          friendlyName == other.friendlyName &&
          type == other.type &&
          frequency == other.frequency;

  @override
  int get hashCode => Object.hash(
    callsign,
    controllerName,
    friendlyName,
    type,
    frequency,
    atisString,
  );
}

enum FacilityType {
  //Delivery: #174ACF
  //Ground: #008856
  //Tower: B82A14
  //Approach: DA5525
  //Center: #008856

  delivery("DEL", "Clearance", Icons.text_snippet),
  ground("GND", "Ground", Icons.grass),
  tower("TWR", "Tower", Icons.cell_tower),
  airport("APT", "Airport", Icons.flight),
  approach("APP", "Approach", Icons.flight_land),
  departure("DEP", "Departure", Icons.flight_takeoff),
  trafficManagement("TMU", "Traffic Management Unit", Icons.traffic),
  center("CTR", "Center", Icons.radar),
  radio("RDO", "Radio", Icons.radio),
  ramp("RMP", "Ramp", Icons.airport_shuttle),
  atis("ATIS", "Atis", Icons.text_snippet),
  fmp("FMP", "FMP", Icons.text_snippet),
  supervisor("SUP", "Supervisor", Icons.person),
  flightService("FSS", "Flight Service Center", Icons.airplanemode_on),
  unknown("UNK", "Unknown", Icons.help),
  all("all", "all", Icons.all_inclusive);

  /*  observer("Observer", Icons.person),
  flightServiceStation("Flight Service Station", Icons.airplanemode_on),
  clearance("Clearance", Icons.text_snippet),
  ground("Ground", Icons.grass),
  tower("Tower",  Icons.cell_tower),
  approach("Approach", Icons.radar),
  center("Center", Icons.flight);*/

  final String name;
  final String internalName;
  final IconData icon;

  const FacilityType(this.internalName, this.name, this.icon);

  static Color facilityToColor(FacilityType type, BuildContext context) {
    switch (type) {
      case FacilityType.delivery:
        return const Color(0xFF174ACF);
      case FacilityType.ground:
        return const Color(0xFF008856);
      case FacilityType.tower:
        return const Color(0xFFB82A14);
      case FacilityType.approach:
        return const Color(0xFFDA5525);
      case FacilityType.departure:
        return Colors.indigo;
      case FacilityType.trafficManagement:
        return Colors.brown;
      case FacilityType.center:
        return Theme.of(context).colorScheme.primary;
      case FacilityType.flightService:
        return Colors.pink;
      case FacilityType.unknown:
        return const Color(0xFF000000);
      default:
        return const Color(0xFF000000);
    }
  }

  String toJson() => internalName;
}

/*
class SubscriptionRegion {
  String prefix;
  List<FacilityType> types;

  SubscriptionRegion(this.prefix, this.types);

  SubscriptionRegion.fromJson(Map<String, dynamic> json)
      : prefix = json['prefix'],
        types = List<FacilityType>.from(
          json['types'].map((model) => FacilityType.values[model]),
        );
  Map<String, dynamic> toJson() => {
    'prefix': prefix,
    'types': types,
  };
}

class SubscriptionFreq {
  List<SubscriptionRegion> regions;

  SubscriptionFreq(this.regions);

  SubscriptionFreq.fromJson(Map<String, dynamic> json)
      : regions = List<SubscriptionRegion>.from(
    json['regions'].map((model) => SubscriptionRegion.fromJson(model)),
  ),
        firebaseId = json['firebaseId'];

  Map<String, dynamic> toJson() => {
    'regions': regions,
    'firebaseId': firebaseId,
  };
}
*/
