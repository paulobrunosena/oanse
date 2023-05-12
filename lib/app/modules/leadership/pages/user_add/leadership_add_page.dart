import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import 'leadership_add_controller.dart';

class LeadershipAddPage extends StatefulWidget {
  final String title;

  const LeadershipAddPage({
    Key? key,
    this.title = 'Cadastre-se',
  }) : super(key: key);

  @override
  LeadershipAddPageState createState() => LeadershipAddPageState();
}

class LeadershipAddPageState extends State<LeadershipAddPage> {
  final controller = Modular.get<LeadershipAddController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [bntSave],
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Modular.to.pop,
        ),
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
            userName,
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
            password,
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      );

  Widget get name => TextFormField(
        validator: Validatorless.required('* campo obrigatório'),
        keyboardType: TextInputType.name,
        onSaved: (value) {
          controller.userName = value;
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          hintText: 'Informe um nome de usuário',
          labelText: 'Nome de usuário',
        ),
      );

  Widget get userName => TextFormField(
        validator: Validatorless.required('* campo obrigatório'),
        keyboardType: TextInputType.name,
        onSaved: (value) {
          controller.userName = value;
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          hintText: 'Informe um nome de usuário',
          labelText: 'Nome de usuário',
        ),
      );

  Widget get password => TextFormField(
        validator: Validatorless.required('* Senha obrigatória'),
        keyboardType: TextInputType.visiblePassword,
        obscureText: true,
        onSaved: (value) {
          controller.password = value;
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          filled: true,
          hintText: 'Informe uma senha',
          labelText: 'Senha',
        ),
      );
}
