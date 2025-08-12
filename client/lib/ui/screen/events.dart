
import 'package:client/core/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventSheet extends StatelessWidget {
  final Event event;
  final ScrollController controller;
  EventSheet(this.event, this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    StringBuffer organizersText = StringBuffer();
    if (event.organisers.length == 1) {
      organizersText.write("${event.organisers[0].region!} presents...");
    } else {
      for (var i = 0; i < event.organisers.length; i++) {
        organizersText.write("");
      }
    }


    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          controller: controller,
          children: [
            Container(
              padding: const EdgeInsets.all(20.0),
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                children: [
                  ClipRRect(
                      child: Image.network(event.banner, fit: BoxFit.scaleDown),
                      borderRadius: BorderRadius.circular(5)
                  ),
                  Text(organizersText.toString(), style: Theme.of(context).textTheme.bodyLarge),
                  Text(event.name, style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.bold)),

                  Text(DateFormat("yyyy/MM/dd HH:mm").format(event.startTime) + "Z", style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),
                  Text(DateFormat("yyyy/MM/dd HH:mm").format(event.endTime) + "Z", style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: event.airports.map((x) => OutlinedButton(child: Row(children: [
                      Icon(Icons.flight),
                      Text(x)
        ],), onPressed: () => print("fdgfd"))).toList(),
                  ),

                  Text(event.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge!),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

}