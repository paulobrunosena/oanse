import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../shared/constants.dart';
import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/widgets/card_menu.dart';
import 'home_controller.dart';

class HomePage extends StatefulWidget {
  final String title;
  final LeadershipModel leadership;

  const HomePage({
    Key? key,
    this.title = "Oanse App",
    required this.leadership,
  }) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final controller = Modular.get<HomeController>();
  late Image logoUrsinho;
  late Image logoFaisca;
  late Image logoFlama;
  late Image logoTocha;
  late Image logoJv;
  late TextTheme textTheme = Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    });
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

    logoFlama = Image.asset("images/flama.png",
        width: 25,
        height: 25,
        //fit: BoxFit.contain,
        fit: BoxFit.fill);

    logoTocha = Image.asset(
      "images/tocha.png",
      width: 35,
      fit: BoxFit.contain,
    );

    logoJv = Image.asset(
      "images/jv.png",
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
        actions: [
          TextButton(
            onPressed: () async {
              await controller.logoutHive();
            },
            child: const Text(
              "Sair",
              style: TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          infoUser,
          menu,
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  Widget get infoUser => Padding(
        padding: const EdgeInsets.all(5.0),
        child: Card(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                dense: true,
                leading: Container(
                  height: 45,
                  width: 45,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent[400],
                    border: Border.all(width: 2, color: Colors.green[800]!),
                    borderRadius: BorderRadius.circular(100), //<-- SEE HERE
                  ),
                  child: logoFlama,
                ),
                title: Text(
                  "Líder",
                  style: textTheme.bodySmall?.copyWith(fontSize: 14),
                ),
                subtitle: Text(widget.leadership.name,
                    style: textTheme.titleSmall?.copyWith(fontSize: 16)),
              ),
            ],
          ),
        ),
      );

  Widget get menu => Container(
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.center,
      child: Wrap(
        direction: Axis.horizontal,
        children: <Widget>[
          CardMenuWidget(
            icone: FontAwesomeIcons.calendarWeek,
            label: "PONTUAÇÃO SEMANAL",
            route: "$routeHome$routeWeeklyScore",
            arguments: widget.leadership,
          ),
          const CardMenuWidget(
            icone: FontAwesomeIcons.book,
            label: "PONTUAÇÃO INDIVIDUAL",
            route: "$routeUser/",
          ),
          CardMenuWidget(
            icone: FontAwesomeIcons.userGroup,
            label: "OANSISTAS",
            route: "$routeOansist/",
            arguments: widget.leadership,
          ),
        ],
      ));
}
