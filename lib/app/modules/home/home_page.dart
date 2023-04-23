import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/constants.dart';
import '../../shared/widgets/card_menu.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({
    Key? key,
    this.title = "Oanse App",
  }) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final controller = Modular.get<HomeController>();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                await controller.logout();
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  child: Wrap(
                    direction: Axis.horizontal,
                    children: const <Widget>[
                      CardMenuWidget(
                        icone: FontAwesomeIcons.noteSticky,
                        label: "CLUBES",
                        route: "$routeClub/",
                      ),
                      CardMenuWidget(
                        icone: FontAwesomeIcons.peopleGroup,
                        label: "LÍDERES",
                        route: "$routeUser/",
                      ),
                      CardMenuWidget(
                        icone: FontAwesomeIcons.user,
                        label: "USUÁRIOS",
                        route: "$routeUser/",
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
