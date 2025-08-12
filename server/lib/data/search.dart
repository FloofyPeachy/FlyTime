import 'package:server/core/model.dart';
import 'package:server/data/vatdata.dart';

class DataSearch {

  //search by: aartc (center, approaches), airport (towers, ground, clearence)
  void init() {

  }

/*  static List<ControlledAirspace> searchFreqs(
      {String? name, String? fir, FacilityType? type }) {

    List<ControlledAirspace> spaces = List.from(StaticData.airspaces);me != null) {
      spaces.removeWhere((v) => !v.name.startsWith(name));
    }
    if (fir != null) {
      spaces.removeWhere((v) => !v.fir.startsWith(fir));
    }

    if (type != null) {
      spaces.removeWhere((v) => !(v.type == type));
    }

    return spaces;
  }*/

  static List<ControlledAirport> searchAirports(String name) {
    if (name.isEmpty || name.length < 3) return [];
    List<ControlledAirport> ports = List.from(StaticData.airports);

    ports.removeWhere(
            (v) => !(v.name.toUpperCase() == name.toUpperCase()));
    if (ports.isEmpty) {
      ports = List.from(StaticData.airports);
      ports.removeWhere(
              (v) => !(v.fullName.toUpperCase() == name.toUpperCase()));
    }
    if (ports.isEmpty) {
      ports = List.from(StaticData.airports);
      ports.removeWhere(
              (v) => !v.friendlyName.toLowerCase().contains(name.toLowerCase()));
    }

    ports.sort((a, b) => a.friendlyName.compareTo(b.friendlyName));
    return ports;
  }

  static List<ControlledAirspace> searchAirspaces(String name) {
    if (name.isEmpty || name.length < 3) return [];
    List<ControlledAirspace> ports = List.from(StaticData.airspaces);
    ports.removeWhere(
            (v) => !(v.name.toUpperCase() == name.toUpperCase()));
    /*if (ports.isEmpty) {
      ports = List.from(StaticData.airspaces);
      ports.removeWhere(
              (v) => !(v.prefix.toUpperCase() == name.toUpperCase()));
    }*/
    if (ports.isEmpty) {
      ports = List.from(StaticData.airspaces);
      ports.removeWhere(
              (v) => !v.callsign.toLowerCase().contains(name.toLowerCase()));
    }

    for (ControlledAirspace space in ports) {
      space.airports = [];
    }
    ports.sort((a, b) => a.callsign.compareTo(b.callsign));
    return ports;
  }
}