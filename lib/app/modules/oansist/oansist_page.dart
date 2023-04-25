import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'oansist_controller.dart';

class OansistPage extends StatefulWidget {
  final String title;

  const OansistPage({
    Key? key,
    this.title = "Oansistas",
  }) : super(key: key);

  @override
  OansistPageState createState() => OansistPageState();
}

class OansistPageState extends State<OansistPage> {
  final controller = Modular.get<OansistController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: Observer(
        builder: (_) {
          if (controller.oansists.isEmpty) {
            return const Center(
              child: Text("Não existe oansistas cadastrados"),
            );
          }

          return ListView.separated(
              separatorBuilder: (context, index) => const Divider(),
              itemCount: controller.oansists.length,
              itemBuilder: (context, int index) {
                return ListTile(
                  title: Text(controller.oansists[index].name ?? "Nome"),
                  subtitle: Text(controller.oansists[index].birthDate ??
                      "Data de nascimento"),
                );
              });
        },
      ),
    );
  }
}
