import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:oanse/app/modules/home/home_store.dart';

class CardMenuWidget extends StatelessWidget {
  final IconData? icone;
  final String? label;
  final String? route;
  final Object? arguments;
  final Color? color;
  final controllerHome = Modular.get<HomeStore>();

  CardMenuWidget(
      {Key? key,
      this.icone,
      this.label,
      this.route,
      this.arguments,
      this.color = Colors.blue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
        color: color,
        elevation: 10,
        child: InkWell(
          child: SizedBox(
            height: 150.0,
            width: 150.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  icone,
                  color: Colors.white,
                  size: 30.0,
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Text(
                  label!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          onTap: () {
            if (route!.contains("login")) {
              controllerHome.logout().then((value) {
                Modular.to.pushReplacementNamed(route!);
              });
            } else {
              Modular.to.pushNamed(route!, arguments: arguments);
            }
          },
        ));
  }
}
