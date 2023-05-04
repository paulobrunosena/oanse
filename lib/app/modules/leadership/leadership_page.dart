import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'leadership_controller.dart';

class LeadershipPage extends StatefulWidget {
  final String title;

  const LeadershipPage({
    Key? key,
    this.title = "Usuários",
  }) : super(key: key);

  @override
  LeadershipPageState createState() => LeadershipPageState();
}

class LeadershipPageState extends State<LeadershipPage> {
  final controller = Modular.get<LeadershipController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (controller.users.isEmpty) {
            return const Center(
              child: Text("Não existe usuário cadastrado"),
            );
          }

          return ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: controller.users.length,
              itemBuilder: (context, int index) {
                return ListTile(
                  title: Text(controller.users[index].name),
                  subtitle: Text(controller.users[index].userName),
                );
              });
        },
      ),
    );
  }
}
