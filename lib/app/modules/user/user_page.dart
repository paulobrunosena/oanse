import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'user_controller.dart';

class UserPage extends StatefulWidget {
  final String title;

  const UserPage({
    Key? key,
    this.title = "Usuários",
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
                  title: Text(controller.users[index].username ?? "Username"),
                  subtitle: Text(controller.users[index].email ?? "E-mail"),
                );
              });
        },
      ),
    );
  }
}
