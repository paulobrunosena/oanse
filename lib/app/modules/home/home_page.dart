import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'home_controller.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({
    Key? key,
    this.title = "Talão Eletrônico",
  }) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final controller = Modular.get<HomeController>();

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
              const Text("Tela Home"),
              ElevatedButton(
                child: const Text("Listar Usuário"),
                onPressed: () {},
              ),
              ElevatedButton(
                child: const Text("Logout"),
                onPressed: () async {
                  await controller.logout();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
