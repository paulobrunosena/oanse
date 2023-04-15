import 'package:flutter/material.dart';

class LogoTransition extends StatelessWidget {
  final Widget childWidget;
  final Animation<double> animation;

  final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

  LogoTransition({Key? key, required this.childWidget, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        child: Center(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Opacity(
            opacity: opacityTween.evaluate(animation),
            child: Container(
              child: childWidget,
            ),
          );
        },
      ),
    ));
  }
}
