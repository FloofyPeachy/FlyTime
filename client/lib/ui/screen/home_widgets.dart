import 'dart:convert';

import 'package:bottom_sheet/bottom_sheet.dart';
import 'package:client/api.dart';
import 'package:client/core/model.dart';
import 'package:client/core/prefs.dart';
import 'package:client/ui/screen/events.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:link_text/link_text.dart';
import 'package:url_launcher/url_launcher.dart';


class ControllerWidget extends StatefulWidget {
  final OnlineController? controller;
  final OnlineControllerMerged? mergedCon;

  const ControllerWidget({super.key, this.controller, this.mergedCon});

  @override
  _ControllerWidgetState createState() => _ControllerWidgetState();
}

class _ControllerWidgetState extends State<ControllerWidget> {
  bool expanded = false;
  bool mouseHovering = false;
  @override
  Widget build(BuildContext context) {
    bool isMerged = widget.mergedCon != null;

    //Extract so the differences are nullified.
    List<String> callsign = [];
    List<String> controllerName = [];
    List<String> friendlyName = [];
    List<FacilityType> type = [];
    List<String> frequency = [];
    int? activeEventId;
    bool isAirport = false;

    isMerged
        ? callsign = widget.mergedCon!.callsign
        : callsign.add(widget.controller!.callsign);
    isMerged
        ? controllerName = widget.mergedCon!.controllerName
        : controllerName.add(widget.controller!.controllerName);
    isMerged
        ? friendlyName = widget.mergedCon!.friendlyName
        : friendlyName.add(widget.controller!.friendlyName);
    isMerged
        ? type = widget.mergedCon!.type
        : type.add(widget.controller!.type);
    isMerged
        ? frequency = widget.mergedCon!.frequency
        : frequency.add(widget.controller!.frequency);
    isMerged
        ? activeEventId = widget.mergedCon!.activeEventId
        : activeEventId = widget.controller!.activeEventId;
    isMerged ? isAirport = widget.mergedCon!.isAirport : isAirport = false;

    List<Color> colors = [];
    if (isMerged) {
      //if (isAirport) colors.add(Colors.blue);
      if (!expanded) {
        for (var value in widget.mergedCon!.type) {
          colors.add(FacilityType.facilityToColor(value, context));
        }
      } else {
        if (isAirport) colors.addAll([Colors.blue, Colors.blue]);
      }

    } else {
      colors.add(
        FacilityType.facilityToColor(widget.controller!.type, context),
      );
      colors.add(
        FacilityType.facilityToColor(widget.controller!.type, context),
      );
    }

    //Add active event color
    if (activeEventId != null) {
      colors.add(Color(0xFF29B473));
    }

    var border = GradientBoxBorder(
      gradient: LinearGradient(colors: colors),
      width: expanded ? (isMerged ? 1.0 : 3) : 1.5,

    );

    return Card(

      child: ExpansionTile(

        shape: border,
        collapsedShape: border,
        onExpansionChanged: (status) {
          setState(() {
            expanded = status;
          });
        },
        leading: MouseRegion(
          onEnter: (PointerEvent details) {
            // Code to execute when the mouse enters
            setState(() {
              mouseHovering = true;
            });
          },
          onExit: (PointerEvent details) {
            // Code to execute when the mouse exits
            setState(() {
              mouseHovering = false;
            });
          },
          child: !mouseHovering ? Icon(
            isMerged
                ? (widget.mergedCon!.isAirport
                      ? Icons.location_city
                      : type[0].icon)
                : type[0].icon,
          ) : InkWell(
            child: Icon(Preferences.subscription.where((element) => callsign.map((e) => e.split('_')[0]).contains(element.prefix)).isNotEmpty ? Icons.star : Icons.star_border),
            onTap: () async {
              String prefix = callsign[0].split('_')[0];
              List<SubscriptionPref> subs = Preferences.subscription.where((element) => element.prefix == prefix).toList();
              if (subs.isEmpty) {
                Preferences.subscription.add(SubscriptionPref(prefix, type));
              } else {
                Preferences.subscription.removeWhere((element) => element.prefix == prefix);
              }
              await Preferences.save();
              await FlyTimeAPI.updateSubscription();
             /* if (subs.isNotEmpty) {
              if (Preferences.subscription.where((element) => element.prefix == prefix && element.types.contains(lType)).isNotEmpty) {

                Preferences.subscription.removeWhere((element) => element.prefix == prefix);
              } else {
                Preferences.subscription.add(SubscriptionPref(prefix, type));
              }*/
              setState(() {});
            }
          ),
        ),
        title: Text(
          isMerged
              ? (isAirport ? "${friendlyName[0]} Airport" : friendlyName[0])
              : friendlyName[0] +
                    (type[0] != FacilityType.center &&
                            type[0] != FacilityType.approach
                        ? " ${widget.controller!.type.name}"
                        : ""),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: isMerged && expanded
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: callsign
                    .mapIndexed(
                      (i, e) => Text(
                        "$e (${frequency[i]})",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                    .toList(),
              ),
        children: [
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isMerged
                ? Column(children: widget.mergedCon!.controllerName.mapIndexed((index, _) => buildSubController(widget.mergedCon!, index)).toList())
                : buildAtisText(widget.controller!.atisString),
          ),
          Divider(),
          activeEventId != null
              ? buildActiveEvent(activeEventId)
              : SizedBox(),
          !isMerged ? Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              controllerName.first,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ) : SizedBox(),

        ],

      ),
    );
  }

  Widget buildAtisText(List<String> atis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: atis
          .map(
            (e) => Linkify(
              onOpen: (link) async {
                if (!await launchUrl(Uri.parse(link.url))) {
                  throw Exception('Could not launch ${link.url}');
                }
              },
              text: "· $e",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
          .toList(),
    );
  }

  Widget buildSubController(OnlineControllerMerged merged, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: merged.callsign.length != index ? 8.0 : 0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color:  FacilityType.facilityToColor(merged.type[index], context),
            width: 2
          )
        ),
        child: ListTile(
          title: Text(merged.type[index].name, style: TextStyle(fontWeight: FontWeight.bold)),
          leading: Icon(merged.type[index].icon)/*Icon(Preferences.subscription.where((element) => element.prefix == merged.callsign[index].split('_')[0] && element.types.contains(merged.type[index])).isNotEmpty ? Icons.star : Icons.star_border)*/,
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${merged.callsign[index]} (${merged.frequency[index]})",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                merged.controllerName[index],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              merged.atisString[0].isNotEmpty ? Divider() : SizedBox(),
              buildAtisText(merged.atisString[index]),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildActiveEvent(int id) {
    return Card(

        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF29B473), Colors.transparent],
              begin: const FractionalOffset(0.0, 0.0),
              end: const FractionalOffset(0.7, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: ListTile(

              leading: Icon(Icons.calendar_today),
              title: Text(
                "Active Event",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle: Text(
                "Press for details",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () async {
                Event event = await FlyTimeAPI.getActiveEvent(id);
                showFlexibleBottomSheet(context: context, builder: (contextl, controller, _) {
                  return EventSheet(event, controller);
                });
              }
          ),
        )
    );
  }
}
