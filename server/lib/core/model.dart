import 'package:server/data/vatdata.dart';

class FlightInfoRegion {
  final Map<String, String> airports;
  final List<Position> positions;
  FlightInfoRegion(this.airports, this.positions);
}

class Organiser {
  final String? region;
  final String?division;
  final String? subdivision;
  final bool organisedByVatsim;
  Organiser(this.region, this.division, this.subdivision, this.organisedByVatsim);

  factory Organiser.fromJson(Map<String, dynamic> json) {
    return Organiser(json['region'], json['division'], json['subdivision'], json['organised_by_vatsim']);
  }

  Map<String, dynamic> toJson() => {
    'region': region,
    'division': division,
    'subdivision': subdivision,
    'organised_by_vatsim': organisedByVatsim,
  };
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
      type:  EventType.values.firstWhere((element) => element.name == json['type']),
      name: json['name'],
      link: json['link'],
      organisers: List<Organiser>.from(json['organisers'].map((e) => Organiser.fromJson(e)).toList()),
      airports: List<String>.from(json['airports'].map((e) => e['icao']).toList()),
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      shortDescription: json['short_description'],
      description: json['description'],
      banner: json['banner'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    'link': link,
    'organisers': organisers,
    'airports': airports,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'short_description': shortDescription,
    'description': description,
    'banner': banner,
  };
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
    required this.airports
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
}

class ControlledAirport {
  final String name;
  final String friendlyName;
  final String fullName;
  late List<(FacilityType, String)> frequency = [];

  ControlledAirport(this.name,this.fullName,  this.friendlyName, this.frequency);

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
          other is ControlledAirport && runtimeType == other.runtimeType &&
              name == other.name && friendlyName == other.friendlyName &&
              fullName == other.fullName;

  @override
  int get hashCode => Object.hash(name, friendlyName, fullName);

  Map<String, dynamic> toJson() => {
    'name': name,
    'friendlyName': friendlyName,
    'fullName': fullName,
    'frequency': frequency,
  };

}

class OnlineController {
  final String callsign;
  final String controllerName;
  final String friendlyName;
  final FacilityType type;
  final String frequency;
  final List<String> atisString;
  int? activeEventId;

  OnlineController({required this.callsign, required this.controllerName, required this.friendlyName,
    required this.type, required this.frequency, required this.atisString, this.activeEventId});


  factory OnlineController.fromJson(Map<String, dynamic> json) {
    FacilityType type = FacilityType.values.firstWhere((element) => json['callsign'].endsWith(element.internalName), orElse: () => FacilityType.unknown);

    //Check if
    return OnlineController(
        callsign: json['callsign'],
        controllerName: json['name'],
        friendlyName: StaticData.conToFriendly(json['frequency'], json['callsign'], type),
       // friendlyName: json['text_atis'] == null ? json['callsign'] : json['text_atis'][0],
        type: type,
        frequency: json['frequency'],
        atisString:  json['text_atis'] == null ? [] : List<String>.from(json['text_atis'] as List));
  }

  Map<String, dynamic> toJson() => {
    'callsign': callsign,
    'controllerName': controllerName,
    'friendlyName': friendlyName,
    'type': type,
    'frequency': frequency,
    'activeEventId': activeEventId,
    'atisString': atisString,
  };


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is OnlineController && runtimeType == other.runtimeType &&
              callsign == other.callsign &&
              controllerName == other.controllerName &&
              friendlyName == other.friendlyName && type == other.type &&
              frequency == other.frequency;

  @override
  int get hashCode =>
      Object.hash(
          callsign, controllerName, friendlyName, type, frequency, atisString);

}


class Frequency {
  final String name;
  final String prefix;
  final String fir;
  final FacilityType type;

  Frequency(this.name, this.prefix, this.type, this.fir);

  @override
  String toString() {
    return 'Frequency{name: $name, fir: $fir, type: $type}';
  }

}


class Position {
  final String callsign;
  final String frequency;
  final FacilityType type;

  Position(this.callsign, this.frequency, this.type);

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
        json['callsign'],
        json['frequency'],
        FacilityType.values.firstWhere((element) => element.internalName == json['type']));
  }
}
/*"DEL": {
"": "Clearance"
},
"GND": {
"": "Ground"
},
"TWR": {
"": "Tower"
},
"APP": {
"": "Approach"
},
"DEP": {
"": "Departure"
},
"CTR": {
"": "Center"
}*/
enum FacilityType {
  supervisor("SUP", "Supervisor"),
  unknown("UNK", "Unknown"),
  all("all", "all"),

  delivery("DEL", "Clearance"),
  ground("GND", "Ground"),

  tower("TWR", "Tower"),
  approach("APP", "Approach"),
  departure("DEP", "Departure"),
  trafficManagement("TMU", "Traffic Management Unit"),
  center("CTR", "Center"),
  radio("RDO", "Radio"),
  flightService("FSS", "Flight Service Center"),
  ramp("RMP", "Ramp"),
  atis("ATIS", "Atis"),
  fmp("FMP", "FMP");

  final String name;
  final String internalName;

  const FacilityType(this.internalName, this.name);

 String toJson() => internalName;

}