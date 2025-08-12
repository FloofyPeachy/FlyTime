import 'dart:convert';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:client/api.dart';
import 'package:client/core/model.dart';
import 'package:client/core/prefs.dart';
import 'package:client/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:http/http.dart' as http;

import '../widgets.dart';
import 'add.dart';
import 'home_widgets.dart';
import 'onboarding.dart';
import 'package:collection/collection.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future stateFuture = Future.value();
  bool editMode = false;
  bool allControllers = false;
  bool showOffline = false;
  bool ready = false;
  final MultiSplitViewController _splitViewController = MultiSplitViewController();
  List<OnlineController> controllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
   /*   showDialog(
        context: context,
        builder: (context) => OnboardingDialog(),
      );
*/
      Stream.periodic(Duration(seconds: 45)).listen((data) {
        setState(() {
          stateFuture = FlyTimeAPI.getOnline(allControllers);
        });
      });
      setState(() {
        stateFuture = FlyTimeAPI.getOnline(allControllers);
      });

      Preferences.load().then((o) => setState(() {
        if (Preferences.userToken != "") {
          FlyTimeAPI.loadSubscriptions().then((value) {
            setState(() {
              stateFuture = FlyTimeAPI.getOnline(allControllers);
            });
            }).onError((error, stackTrace) {
            showDialog(
              context: context,
              builder: (context) => OnboardingDialog(),
            );
          });


        }
        ready = true;
        print("Ready!");
      }));
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseMessaging.instance.getToken().then((value) async {});
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
        return  SafeArea(
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? 40 : null,
              backgroundColor: Colors.transparent,
              title: Text("FlyTime"),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    if (Preferences.userToken != "") {
                      FlyTimeAPI.updateSubscription();
                    }
                  },
                ),
                IconButton(
                  onPressed: () {
                    if (Preferences.userToken != "") {
                      FlyTimeAPI.loadSubscriptions();
                    }
                    setState(() {
                      stateFuture = FlyTimeAPI.getOnline(allControllers);
                    });
                  },
                  icon: Icon(Icons.subdirectory_arrow_left_sharp),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRegionSheet()),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddRegionSheet()),
                  ),
                ),
              ],
            ),
            body: ready ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      ResponsiveBreakpoints.of(context).smallerThan(TABLET) ? InkWell(
                        child: Text(
                          "VATSIM Controllers",
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => setState(() {
                          showOffline = !showOffline;
                        }),
                      ) : SizedBox(),
                      Expanded(child: Divider()),
                      Preferences.subscription.isEmpty
                          ? SizedBox()
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  allControllers = !allControllers;
                                  stateFuture = FlyTimeAPI.getOnline(
                                    allControllers,
                                  );
                                });
                              },
                              icon: Icon(
                                !allControllers
                                    ? Icons.star
                                    : Icons.star_border,
                              ),
                        tooltip: "Toggle favorites",
                            ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            stateFuture = FlyTimeAPI.getOnline(allControllers);

                          });
                        },
                        icon: Icon(Icons.refresh),
                        tooltip: "Refresh",
                      ),
                    ],
                  ),
                  FutureBuilder(
                    future: stateFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      if (snapshot.hasData) {
                        controllers = List.of(snapshot.data!);
                        List<OnlineControllerMerged> mergedControllers = [];

                        controllers.removeWhere((element) =>
                        !Preferences.filter.contains(element.type));

                        List<SubscriptionPref> missingControllers = showOffline
                            ? List.from(Preferences.subscription)
                            : [];
                        if (Preferences.combineCenters) {
                          Map<String, List<OnlineController>> grouped = {};
                          for (var value in controllers) {
                            if (!(value.type == FacilityType.center || value.type == FacilityType.approach || value.type == FacilityType.trafficManagement || value.type == FacilityType.flightService)) continue;
                            if (!grouped.containsKey(value.friendlyName)) {
                              grouped[value.friendlyName] = [];
                            }
                            grouped[value.friendlyName]!.add(value);
                          }


                          grouped.forEach((key, value) {
                            if (value.length > 1) {
                              mergedControllers.add(
                                OnlineControllerMerged(value, false),
                              );
                              controllers.removeWhere((element) =>
                              element.friendlyName == key);
                            }
                          });

                        }

                        if (Preferences.combineAirports) {
                          Map<String, List<OnlineController>> grouped = {};
                          for (var value in controllers) {
                            if ((value.type != FacilityType.ground && value.type != FacilityType.delivery && value.type != FacilityType.tower  && value.type !=  FacilityType.departure  && value.type != FacilityType.trafficManagement))  continue;
                            if (!grouped.containsKey(value.callsign.split("_")[0])) {
                              grouped[value.callsign.split("_")[0]] = [];
                            }
                            grouped[value.callsign.split("_")[0]]!.add(value);
                          }


                          grouped.forEach((key, value) {
                            if (value.length > 1) {
                              mergedControllers.add(
                                OnlineControllerMerged(value, true),
                              );

                              for (var value1 in value) {
                                controllers.remove(value1);
                              }
                            } else {
                              controllers.addAll(value);
                            }
                          });

                        }

                        Map<dynamic, Widget> theList = {};
                        for (var value in controllers) {
                          theList[value] = ControllerWidget(controller: value);
                        }

                        for (var value in mergedControllers) {
                          theList[value] = ControllerWidget(mergedCon: value);
                        }

                        //Sort it.
                        theList = Map.fromEntries(theList.entries.toList()
                          ..sort((e1, e2) {
                            int byType = Enum.compareByIndex(e2.key.type is List<FacilityType> ? e2.key.type[0] : e2.key.type, e1.key.type is List<FacilityType>  ?  e1.key.type[0] : e1.key.type);
                            if (byType != 0) return byType;
                            return e1.key.friendlyName.toString().compareTo(e2.key.friendlyName.toString());
                          }));




                        //  missingControllers.add(Preferences.subscription.where((element) => element.$2.contains(FacilityType.all)).map((e) => (e.$1, FacilityType.all)).first);
                        for (var value in controllers) {
                          missingControllers.removeWhere(
                                (x) =>
                            value.callsign.contains(x.prefix) &&
                                x.types.any(
                                      (type) => value.callsign.endsWith(
                                    type.internalName,
                                  ),
                                ),
                          );
                        }


                        if (ResponsiveBreakpoints.of(context).largerThan(TABLET)) {
                          _splitViewController.areas = [
                            Area(data: statFilterView(), flex: 1),
                            Area(data: ListView(
                              shrinkWrap: true,
                              children: theList.values.toList(),
                            ), flex: 3)
                          ];
                        }


                        return Expanded(
                            child: ResponsiveBreakpoints.of(context).largerThan(MOBILE) ? MultiSplitView(
                              controller: _splitViewController,
                              builder: (BuildContext context, Area area) => area.data,
                            ) : ListView(
                              shrinkWrap: true,
                              children: theList.values.toList(),
                            )
                        );

                      } else {
                        return Text("Loading controller data...");
                      }
                      return Text("Yay!");
                    },
                  ),
                ],
              ),
            ) : Text("Loading preferences..."),
          ),
        );

  }

  Widget statFilterView() {
    List<FacilityType> filterView = [];
    List<FacilityType> unselectedView = [];

    filterView.addAll(FacilityType.values);
    unselectedView.addAll(FacilityType.values);

    filterView.removeWhere((element) => controllers.where((element1) => element1.type == element).isEmpty);
    unselectedView.removeWhere((element) => controllers.where((element1) => element1.type == element).isNotEmpty);
    filterView.sort((e1, e2) => Enum.compareByIndex(e2, e1));
    return Column(
      children: [

        ListView(
          shrinkWrap: true,
          children: filterView.map((type) => CheckboxListTile(
            title: Text("${type.name} (${controllers.where((element) => element.type == type).length})"),
            secondary: Icon(type.icon),
            contentPadding: EdgeInsets.all(0),
            value: Preferences.filter.contains(type),
            onChanged: (bool? value) {
              setState(() {
                Preferences.filter.contains(type) ? Preferences.filter.remove(type) : Preferences.filter.add(type);
              });
            },
          )).toList()
        ),
        Divider(),
        SingleChildScrollView(
          child: ExpansionTile(
            title: Text("Offline"),
            children: [
              ListView(
                  shrinkWrap: true,
                  children: unselectedView.map((type) => CheckboxListTile(
                    title: Text(type.name +  " (0)"),
                    secondary: Icon(type.icon),
                    contentPadding: EdgeInsets.all(0),
                    value: Preferences.filter.contains(type),
                    onChanged: (bool? value) {
                      setState(() {
                        Preferences.filter.contains(type) ? Preferences.filter.remove(type) : Preferences.filter.add(type);
                      });
                    },
                  )).toList()
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget buildOfflineControllerCard(String callsign, List<FacilityType> type) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ListTile(
        leading: Icon(Icons.offline_bolt),
        title: Text(
          callsign,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          type.map((e) => e.name).join(", "),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

}
