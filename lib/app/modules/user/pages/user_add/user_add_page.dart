import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:validatorless/validatorless.dart';

import 'user_add_controller.dart';

class UserAddPage extends StatefulWidget {
  final String title;

  const UserAddPage({
    Key? key,
    this.title = 'Cadastre-se',
  }) : super(key: key);

  @override
  UserAddPageState createState() => UserAddPageState();
}

class UserAddPageState extends State<UserAddPage> {
  final controller = Modular.get<UserAddController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [bntSave],
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: Modular.to.pop,),
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
            userName,
            const SizedBox(
              height: 10,
            ),
            email,
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

  Widget get userName => TextFormField(
        validator: Validatorless.required('* Nome de usuário obrigatório'),
        keyboardType: TextInputType.name,
        onSaved: (value) {
          controller.userName = value;
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: 'Informe um nome de usuário',
            labelText: 'Nome de usuário',),
      );

  Widget get email => TextFormField(
        validator: Validatorless.multiple([
          Validatorless.required('* Campo obrigatório'),
          Validatorless.email('* E-mail inválido'),
        ]),
        keyboardType: TextInputType.emailAddress,
        onSaved: (value) {
          controller.email = value;
        },
        decoration: const InputDecoration(
            border: OutlineInputBorder(),
            filled: true,
            hintText: 'Informe um e-mail',
            labelText: 'E-mail',),
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
            labelText: 'Senha',),
      );
}
