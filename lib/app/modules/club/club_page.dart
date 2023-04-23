import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/constants.dart';
import '../../shared/widgets/card_menu.dart';
import 'club_controller.dart';

class ClubPage extends StatefulWidget {
  final String title;

  const ClubPage({
    Key? key,
    this.title = "Clubes",
  }) : super(key: key);

  @override
  ClubPageState createState() => ClubPageState();
}

class ClubPageState extends State<ClubPage> {
  final controller = Modular.get<ClubController>();
  late Image logoUrsinho;
  late Image logoFaisca;

  @override
  void initState() {
    super.initState();
    init();
  }

  init() {
    logoUrsinho = Image.asset(
      "images/ursinho.png",
      width: 35,
      fit: BoxFit.contain,
    );

    logoFaisca = Image.asset(
      "images/faisca.png",
      width: 35,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (controller.clubs.isEmpty) {
            return const Center(
              child: Text("Não existe clube cadastrado"),
            );
          }

          return ListView(children: <Widget>[
            Column(children: <Widget>[
              Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.center,
                  child: menuClubs)
            ])
          ]);
        },
      ),
    );
  }

  Widget get menuClubs {
    List<Widget> listClub = [];
    for (var club in controller.clubs) {
      IconData? clubIcon;
      Image? clubImage;
      String clubRoute = "$routeHome/";
      Color clubColor = Colors.indigo;
      switch (club.name) {
        case ursinho:
          clubColor = Colors.red;
          clubImage = logoUrsinho;
          break;
        case faisca:
          clubColor = Colors.yellow;
          clubImage = logoFaisca;
          break;
        case flama:
          clubColor = Colors.green;
          clubIcon = FontAwesomeIcons.fireFlameSimple;
          break;
        case tocha:
          clubColor = Colors.blue;
          clubIcon = FontAwesomeIcons.fireFlameCurved;
          break;
        case jv:
          clubColor = Colors.black;
          clubIcon = FontAwesomeIcons.j;
          break;
        default:
          clubColor = Colors.green[900]!;
          clubIcon = FontAwesomeIcons.v;
      }
      listClub.add(CardMenuWidget(
        label: club.name,
        icone: clubIcon,
        image: clubImage,
        route: clubRoute,
        backGroundColor: clubColor,
      ));
    }

    return Wrap(direction: Axis.horizontal, children: listClub);
  }
}
