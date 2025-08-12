import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends StatefulWidget {
  GlobalKey<NavigatorState> navigator;

  TitleBar({super.key, required this.navigator});
  @override
  State<StatefulWidget> createState() => _TitleBar();

}

class _TitleBar extends State<TitleBar> {
  bool settingsOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      //1D1D1D
      color: Theme.of(context).colorScheme.surfaceBright,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails details) {
          windowManager.startDragging();
        },
        onSecondaryLongPressDown: (LongPressDownDetails details) {
          windowManager.popUpWindowMenu();
        },
        child: Row(

          children: [
            widget.navigator.currentState != null && widget.navigator.currentState!.canPop() ? MaterialButton(
              minWidth: 0,
              onPressed: () {
                widget.navigator.currentState!.pop();
              },
              child: const Icon(Icons.arrow_back, size: 24),

            ) : SizedBox(),
            MaterialButton(
              onPressed: () {

              },
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text("FlyTime", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                      Icon(Icons.flight, color: Theme.of(context).colorScheme.primary, size: 16,)
                    ],
                  ),
                ),
              ),
            ),


            const Spacer(),
            MaterialButton(
              minWidth: 0,
              onPressed: () {
                // Minimize the window
                windowManager.minimize();
              },
              child: const Icon(Icons.horizontal_rule, size: 16),
            ),
            MaterialButton(
              minWidth: 0,
              onPressed: () async {
                // Minimize the window
                await windowManager.isMaximized() ? windowManager.unmaximize() : windowManager.maximize();
              },
              child: const Icon(Icons.check_box_outline_blank_rounded, size: 16),
            ),
            MaterialButton(
              minWidth: 0,
              onPressed: () {
                // Minimize the window]
                windowManager.close();
              },
              child: const Icon(Icons.close, size: 16),
            ),

          ],
        ),
      ),
    );
  }
}