import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/constants.dart';
import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/widgets/card_menu.dart';
import 'home_leadership_controller.dart';

class HomeLeadershipPage extends StatefulWidget {
  final String title;
  final LeadershipModel? leadership;

  const HomeLeadershipPage({
    Key? key,
    this.title = "Oanse App",
    this.leadership,
  }) : super(key: key);

  @override
  HomeLeadershipPageState createState() => HomeLeadershipPageState();
}

class HomeLeadershipPageState extends State<HomeLeadershipPage> {
  final controller = Modular.get<HomeLeadershipController>();

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
          TextButton(
            onPressed: () async {
              await controller.logout();
            },
            child: const Text(
              "Sair",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: widget.leadership != null
          ? ListView(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.center,
                        child: Wrap(
                          direction: Axis.horizontal,
                          children: <Widget>[
                            CardMenuWidget(
                              icone: FontAwesomeIcons.noteSticky,
                              label: "CLUBES ${widget.leadership!.name}",
                              route: "$routeClub/",
                            ),
                          ],
                        )),
                  ],
                ),
              ],
            )
          : const Center(child: Text('Nenhum líder selecionado')),
    );
  }
}
