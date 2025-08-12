import 'dart:async';

import 'package:client/api.dart';
import 'package:client/core/model.dart';
import 'package:client/core/prefs.dart';
import 'package:client/core/util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddRegionSheet extends StatefulWidget {
  const AddRegionSheet({Key? key}) : super(key: key);

  @override
  State<AddRegionSheet> createState() => _AddRegionSheetState();
}

class _AddRegionSheetState extends State<AddRegionSheet> {
  bool addByAirport = false;

  List<ControlledAirspace> airspaces = []; // <Controll// edAirspace>
  List<ControlledAirport> airports = [];

  List<ControlledAirspace> selectedAirspaces = [];
  Map<ControlledAirport, List<FacilityType>> selectedAirports = {};

  Timer? _debounce;
  List<bool> selected = [false, false, false];

  bool editMode = false;
  ScrollController scrollController = new ScrollController();
  _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
        List <ControlledAirspace> airspaces = await FlyTimeAPI.searchAirspaces(query);
        List<ControlledAirport> airports = await FlyTimeAPI.searchAirports(query);
      setState(()  {
        this.airspaces = airspaces;
        this.airports = airports;
        scrollController.animateTo(0, duration: Duration(milliseconds: 200), curve: Curves.linear);
      });

      /*FlyTimeAPI.searchAirports(query).then((value) {
        setState(() {
          airports = value;
        });
      });*/
    });
  }
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Are you sure you want to leave this page?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await _showBackDialog() ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: selectedAirports.isNotEmpty || selectedAirspaces.isNotEmpty ? FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () async {
              for (var value in selectedAirspaces) {
                for (var prefix in value.prefix) {
                  Preferences.subscription.add(SubscriptionPref(prefix, [FacilityType.all]));
                }
              }

              selectedAirports.forEach((k,v) {
                Preferences.subscription.add(SubscriptionPref(k.name, v));
              });

              bool success = false;
              await Preferences.save();
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Updating subscriptions on server..."),
                    content: FutureBuilder(
                      future: FlyTimeAPI.updateSubscription(),
                      builder: (context, asyncSnapshot) {
                        if (asyncSnapshot.hasError) {
                          return Text("${asyncSnapshot.error}");
                        }
                        if (asyncSnapshot.hasData) {
                          Navigator.pop(context);
                          success = true;
                          return Text("Done!");

                        }
                        return CircularProgressIndicator(value: null);
                      }
                    ),
                  );
                },
              );
              Navigator.pop(context);
            },
          ) : SizedBox(),
          appBar: AppBar(title: Text("Add Controller",
          ),
          actions: [
            IconButton(icon: Icon(Icons.edit), onPressed: () {
          setState(() {
            editMode = !editMode;
          });
            },)
            ],
          ),
          body: Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: !editMode ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: SearchAnchor(
                    builder: (context, controller) {
                      return SearchBar(
                        padding: const WidgetStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        leading: const Icon(Icons.search),
                        controller: controller,
                        onSubmitted: (value) {
                          //controller.close();
                        },
                        onChanged: _onSearchChanged,
                      );
                    },
                    suggestionsBuilder: (context, controller) {
                      return [];
                    },
                  ),
                ),
                Text(
                  "Search by center name, airport name, or airport ICAO code",
                  style: TextStyle(color: Colors.grey),
                ),
                Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Centers (${airports.length})",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: dH(context),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          controller: scrollController,
                          itemCount: airspaces.length,
                          itemBuilder: (context, index) {
                            return buildAirspaceCard(airspaces[index], context);
                          },
                        ),
                      ),
                      Divider(),
                      Text(
                        "Airports (${airports.length})",
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: dH(context) * 0.4,
                        ),
                        child: ListView.builder(
                          //controller: scrollController,
                          shrinkWrap: true,
                          itemCount: airports.length,
                          itemBuilder: (context, index) {
                            return buildAirportCard(airports[index], context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                addByAirport ? Container() : Container(),
              ] : [
                Text(
                  "Going To Be Added (${selectedAirspaces.length + selectedAirports.length})",
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  itemCount: selectedAirports.length,
                  itemBuilder: (context, index) {
                    return buildAirportCard(selectedAirports.keys.toList()[index], context);
                  },
                ),
                ListView.builder(
                  shrinkWrap: true,
                  controller: scrollController,
                  itemCount: selectedAirspaces.length,
                  itemBuilder: (context, index) {
                    return buildAirspaceCard(selectedAirspaces[index], context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  buildAirspaceCard(ControlledAirspace airspace, BuildContext context) {
    return Card(
      color: selectedAirspaces.contains(airspace) ? Theme.of(context).colorScheme.primary.withAlpha(80): Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
          title: Text("${airspace.callsign} - ${airspace.name} - ${airspace.prefix}", style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(airspace.frequencies != null ? "${airspace.frequencies!.join(", ")}" : ""),
          onTap: () {
            setState(() {
              if (!selectedAirspaces.contains(airspace)) {
                selectedAirspaces.add(airspace);
              } else {
                selectedAirspaces.remove(airspace);
              }
            });

          }
      ),
    );
  }

  buildAirportCard(ControlledAirport airport, BuildContext context) {
    List<FacilityType> options = [FacilityType.tower, FacilityType.ground, FacilityType.delivery];

    return Card(
      color: selectedAirports.keys.contains(airport) ? Theme.of(context).colorScheme.primary.withAlpha(80) :  Theme.of(context).colorScheme.surfaceContainerLow,
      child: ExpansionTile(
          title: Text("${airport.friendlyName} - ${airport.fullName} - ${airport.name}", style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(airport.friendlyName),

          children: [
              SizedBox(
                width: double.infinity,
                child: ToggleButtons(
                  renderBorder: false,
                  direction: Axis.vertical,
                  onPressed: (index) {
                    setState(() {
                      print(selected[index]);
                      selected[index] = !selected[index];
                      print(selected[index]);
                      if (selected[0] == false && selected[1] == false && selected[2] == false) {
                        setState(() {
                          selectedAirports.remove(airport);
                          print("removing!!");
                        });
                      } else {
                        selectedAirports[airport] = options.where((element) => selected[options.indexOf(element)]).toList();
                      }
                    });
                  },
                  isSelected: selected,
                  children: options.map((x) => buildAirportFrequencyTile(x, selected[options.indexOf(x)], context)).toList(),

                ),
              )
            ],

        onExpansionChanged: (state) {
            if (!state) {
              if (selected[0] == false && selected[1] == false && selected[2] == false) {
                setState(() {
                  selectedAirports.remove(airport);
                  print("removing!!");
                });
                return;
              }

              setState(() {
                List<FacilityType> types = [];
                if (selected[0]) {
                  types.add(FacilityType.tower);
                }
                if (selected[1]) {
                  types.add(FacilityType.ground);
                }
                if (selected[2]) {
                  types.add(FacilityType.delivery);
                }

                selectedAirports[airport] = types;
              });

            } else {

              List<bool> leSelected = [false, false, false];

              if (selectedAirports.containsKey(airport)) {
                List<bool> mapped =  selectedAirports[airport]!.map((x) => options.contains(x)).toList();
                if (selectedAirports[airport]!.contains(FacilityType.tower)) leSelected[0] = true;
                if (selectedAirports[airport]!.contains(FacilityType.ground)) leSelected[1] = true;
                if (selectedAirports[airport]!.contains(FacilityType.delivery)) leSelected[2] = true;
              }
              print("fg");
              setState(() {
                selected = leSelected;
              });

            }
        },

        /*onTap: () {
            setState(() {
              if (!selectedAirports.keys.contains(airport)) {
                selectedAirports[airport] = [FacilityType.all];
              } else {
                selectedAirports.remove(airport);
              }
            });


          }*/
      ),
    );
  }

  Widget buildAirportFrequencyTile(FacilityType type, bool selected, BuildContext context) {
    return
      Card(
        color: selected ? FacilityType.facilityToColor(type, context) : Theme.of(context).colorScheme.surfaceContainerHigh,
        child: ListTile(
          leading: Icon(type.icon),
          title: Text(type.name),
        ),

    );
  }
}

