import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import 'oansist_add_controller.dart';

class OansistAddPage extends StatefulWidget {
  final String title;

  const OansistAddPage({
    Key? key,
    this.title = "Cadastrar Oansista",
  }) : super(key: key);

  @override
  OansistAddPageState createState() => OansistAddPageState();
}

class OansistAddPageState extends State<OansistAddPage> {
  final controller = Modular.get<OansistAddController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [bntSave],
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: Modular.to.pop),
      ),
      body: form,
    );
  }

  Widget get bntSave => IconButton(
        onPressed: controller.register,
        icon: const Icon(Icons.save_rounded),
      );

  Widget get form => Form(
        key: controller.formController.key,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: <Widget>[
            name,
            const SizedBox(
              height: 10,
            ),
            birthDate,
            const SizedBox(
              height: 10,
            ),
            club,
            const SizedBox(
              height: 10,
            ),
            gender,
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      );

  Widget get name => TextFormField(
        validator: Validatorless.required("* Campo obrigatório"),
        keyboardType: TextInputType.name,
        onSaved: (value) {
          controller.name = value;
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: "Informe om nome do oansista",
            labelText: "Nome"),
      );

  Widget get birthDate => TextFormField(
        validator: Validatorless.multiple([
          Validatorless.required("* Campo obrigatório"),
          Validatorless.date("* Data inválida"),
        ]),
        keyboardType: TextInputType.emailAddress,
        onSaved: (value) {
          controller.birthDate = value;
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: "Informe a data de nascimento",
            labelText: "Data de nascimento"),
      );

  Widget get club => TextFormField(
        validator: Validatorless.required("* Campo obrigatório"),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        onSaved: (value) {
          controller.clubId = int.parse(value ?? "0");
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: "Informe o clube",
            labelText: "Clube oanse"),
      );

  Widget get gender => TextFormField(
        validator: Validatorless.required("* Campo obrigatório"),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        onSaved: (value) {
          controller.gender = value;
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: "Informe o gênero",
            labelText: "Gênero"),
      );
}
