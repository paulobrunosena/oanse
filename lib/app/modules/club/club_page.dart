import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/constants.dart';
import '../../shared/model/club/club_model.dart';
import '../../shared/widgets/card_menu.dart';
import 'club_controller.dart';

class ClubPage extends StatefulWidget {
  final String title;

  const ClubPage({
    Key? key,
    this.title = 'Clubes',
  }) : super(key: key);

  @override
  ClubPageState createState() => ClubPageState();
}

class ClubPageState extends State<ClubPage> {
  final controller = Modular.get<ClubController>();
  late Image logoUrsinho;
  late Image logoFaisca;
  late Image logoFlama;
  late Image logoTocha;
  late Image logoJv;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() {
    logoUrsinho = Image.asset(
      'images/ursinho.png',
      width: 35,
      fit: BoxFit.contain,
    );

    logoFaisca = Image.asset(
      'images/faisca.png',
      width: 35,
      fit: BoxFit.contain,
    );

    logoFlama = Image.asset(
      'images/flama.png',
      width: 35,
      fit: BoxFit.contain,
    );

    logoTocha = Image.asset(
      'images/tocha.png',
      width: 35,
      fit: BoxFit.contain,
    );

    logoJv = Image.asset(
      'images/jv.png',
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
              child: Text('Não existe clube cadastrado'),
            );
          }

          return ListView(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    child: menuClubs,
                  )
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget get menuClubs {
    final List<Widget> listClub = [];
    for (var club in controller.clubs) {
      IconData? clubIcon;
      Image? clubImage;
      String clubRoute = '$routeOansist/';
      Color clubColor = Colors.indigo;
      ClubModel? arguments;
      switch (club.name) {
        case ursinho:
          clubColor = Colors.red;
          clubImage = logoUrsinho;
          clubRoute = '$routeClub$routeClubDetails';
          arguments = club;
          break;
        case faisca:
          clubColor = Colors.yellow;
          clubImage = logoFaisca;
          clubRoute = '$routeClub$routeClubWeeklyScore';
          arguments = club;
          break;
        case flama:
          clubColor = Colors.green;
          clubImage = logoFlama;
          break;
        case tocha:
          clubColor = Colors.blue;
          clubImage = logoTocha;
          break;
        case jv:
          clubColor = Colors.black;
          clubImage = logoJv;
          break;
        default:
          clubColor = Colors.green[900]!;
          clubIcon = FontAwesomeIcons.v;
      }
      listClub.add(
        CardMenuWidget(
          label: club.name,
          icone: clubIcon,
          image: clubImage,
          route: clubRoute,
          arguments: arguments,
          backGroundColor: clubColor,
        ),
      );
    }

    return Wrap(direction: Axis.horizontal, children: listClub);
  }
}
