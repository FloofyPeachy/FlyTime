import 'dart:math';

import 'package:flutter/material.dart';

Route createRoute(Widget page2, bool fade) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page2,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {


      if (fade) {
        var begin = 0.0;
        var end = 1.0;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return FadeTransition(

          opacity: animation.drive(tween),
          child: child,
        );
      } else {
        var begin = const Offset(1.5, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      }
    },
  );
}

double dH(BuildContext context) => MediaQuery.of(context).size.height;
double dW(BuildContext context) => MediaQuery.of(context).size.width;

TextStyle textStyleFromDw(BuildContext context, double dw, [TextStyle extra = const TextStyle()]) {
  return TextStyle(
    fontSize: dW(context) * dw,
  ).merge(extra);
}
TextStyle textStyleFromDh(BuildContext context, double dw, [TextStyle extra = const TextStyle()]) {
  return TextStyle(
    fontSize: dH(context) * dw,
  ).merge(extra);
}