import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:oanse/app/shared/constants.dart';

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
              ElevatedButton(
                child: const Text("Listar Usuário"),
                onPressed: () async {
                  Modular.to.pushNamed('$routeUser/');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
