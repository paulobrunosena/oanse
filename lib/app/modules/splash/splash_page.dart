import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'components/logo_transition.dart';
import 'splash_controller.dart';

class SplashPage extends StatefulWidget {
  final String title;
  const SplashPage({Key? key, this.title = "Splash"}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final controller = Modular.get<SplashController>();

  late Image splash;
  late AnimationController _controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    splash = Image.asset(
      "images/logo.png",
      width: 180.0,
      //fit: BoxFit.cover,
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    animation = CurvedAnimation(parent: _controller, curve: Curves.ease);

    animation.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2)).then((_) {
          _controller.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        await controller.redirectPageLoginLeadership();
      }
    });
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(splash.image, context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey[300],
        child: Stack(
          children: <Widget>[
            LogoTransition(
              childWidget: splash,
              animation: animation,
            ),
          ],
        ),
      ),
    );
  }
}
