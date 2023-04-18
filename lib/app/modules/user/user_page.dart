import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'user_controller.dart';

class UserPage extends StatefulWidget {
  final String title;

  const UserPage({
    Key? key,
    this.title = "Talão Eletrônico",
  }) : super(key: key);

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  final controller = Modular.get<UserController>();

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
              ElevatedButton(
                child: const Text("Listar Usuário"),
                onPressed: () async {
                  await controller.register();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
