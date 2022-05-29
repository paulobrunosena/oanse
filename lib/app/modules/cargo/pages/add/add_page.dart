import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'add_store.dart';

class AddPage extends StatefulWidget {
  final String title;
  const AddPage({Key? key, this.title = 'Adicionar cargo'}) : super(key: key);
  @override
  AddPageState createState() => AddPageState();
}

class AddPageState extends State<AddPage> {
  final controller = Modular.get<AddStore>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
            key: controller.formController.key,
            child: Column(
              children: [
                const SizedBox(height: 24.0),
                TextFormField(
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Nome',
                    hintText: 'Informe um nome para o cargo',
                    suffixStyle: TextStyle(color: Colors.green),
                  ),
                  onSaved: (String? value) {
                    controller.cargo.nome = value;
                  },
                  validator: controller.validateNome,
                ),
                const SizedBox(height: 24.0),
                TextFormField(
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Informe uma breve descrição sobre o cargo',
                    labelText: 'Descrição',
                  ),
                  maxLines: 3,
                  onSaved: (String? value) {
                    controller.cargo.descricao = value;
                  },
                  validator: controller.validateDescricao,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: controller.save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // NEW
                  ),
                  child: const Text('SALVAR'),
                ),
              ],
            )),
      ),
    );
  }
}
