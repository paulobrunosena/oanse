import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../model/cargo.dart';
import 'edit_store.dart';

class EditPage extends StatefulWidget {
  final String title;
  final Cargo cargo;
  const EditPage({Key? key, this.title = 'Editar cargo', required this.cargo})
      : super(key: key);
  @override
  EditPageState createState() => EditPageState();
}

class EditPageState extends State<EditPage> {
  final controller = Modular.get<EditStore>();

  @override
  void initState() {
    super.initState();
    controller.setCargo(widget.cargo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {},
          ),
        ],
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
                  initialValue: widget.cargo.nome,
                  onSaved: (String? value) {
                    controller.cargo.nome = value;
                  },
                  onChanged: (String? value) {
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
                  initialValue: widget.cargo.descricao,
                  onSaved: (String? value) {
                    controller.cargo.descricao = value;
                  },
                  validator: controller.validateDescricao,
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: controller.update,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50), // NEW
                  ),
                  child: const Text('EDITAR'),
                ),
              ],
            )),
      ),
    );
  }
}
