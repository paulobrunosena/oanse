import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/models/user_model.dart';
import 'components/card_menu/card_menu_widget.dart';
import 'components/info_usuario/info_usuario_widget.dart';
import 'home_store.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({Key? key, this.title = "Home"}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final UserModel usuario =
      UserModel(nome: "Paulo Sena", cpf: "999.999.999-99");
  final store = Modular.get<HomeStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          Column(
            children: <Widget>[
              const SizedBox(
                height: 10,
              ),
              InfoUsuarioWidget(
                usuario: usuario,
              ),
              const SizedBox(
                height: 10,
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                direction: Axis.horizontal,
                children: <Widget>[
                  CardMenuWidget(
                    icone: Icons.people,
                    label: "CARGO",
                    route: "/cargo/",
                  ),
                  CardMenuWidget(
                    icone: Icons.add_business_rounded,
                    label: "CLUBES",
                    route: "/login/",
                  ),
                  CardMenuWidget(
                    icone: Icons.add_shopping_cart_rounded,
                    label: "MATERIAL",
                    route: "/login/",
                  ),
                  CardMenuWidget(
                    icone: Icons.border_color_sharp,
                    label: "MANUAL",
                    route: "/login/",
                  ),
                  CardMenuWidget(
                    icone: Icons.accessibility_new,
                    label: "LÍDERES",
                    route: "/login/",
                  ),
                  CardMenuWidget(
                    icone: Icons.add_reaction,
                    label: "OANSISTAS",
                    route: "/login/",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
