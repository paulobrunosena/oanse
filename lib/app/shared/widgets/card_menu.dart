import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CardMenuWidget extends StatelessWidget {
  final Color? backGroundColor;
  final Color? frontGroundColor;
  final IconData? icone;
  final Image? image;
  final String label;
  final String route;
  final Object? arguments;

  const CardMenuWidget({
    Key? key,
    this.icone,
    required this.label,
    required this.route,
    this.arguments,
    this.backGroundColor = Colors.indigoAccent,
    this.frontGroundColor = Colors.white,
    this.image,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: backGroundColor,
        elevation: 2,
        child: InkWell(
          onTap: () {
            Modular.to.pushNamed(route, arguments: arguments);
          },
          child: SizedBox(
            height: 108.0,
            width: 108.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                icone != null
                    ? Icon(
                        icone,
                        color: frontGroundColor,
                        size: 30.0,
                      )
                    : Container(
                        child: image,
                      ),
                const SizedBox(
                  height: 10.0,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: frontGroundColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),);
  }
}
