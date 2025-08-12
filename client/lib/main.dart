import 'dart:io';

import 'package:client/ui/titlebar.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:window_manager/window_manager.dart';

import 'ui/screen/home.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    windowManager.waitUntilReadyToShow(
        WindowOptions(
          title: 'FlyTime',
          titleBarStyle: TitleBarStyle.hidden,
        )
    );
  }

  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlyTime',
        navigatorKey: _navigator,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: Material(
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) {
                    return Column(
                      children: [
                        Platform.isWindows || Platform.isLinux || Platform.isMacOS ? TitleBar(navigator: _navigator) : SizedBox(),
                        Expanded(child: child!),

                      ],
                    );
                  },
                ),
              ]
            )
          ),
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
      home: const MainScreen()
    );
  }
}

