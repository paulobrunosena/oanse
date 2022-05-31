import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../model/cargo.dart';
import 'form_dialog_store.dart';

class FormDialogWidget extends StatefulWidget {
  final String title;
  final String labelButton;
  final Cargo? cargo;
  const FormDialogWidget(
      {Key? key,
      this.title = "Adicionar cargo",
      this.labelButton = "Salvar",
      this.cargo})
      : super(key: key);

  @override
  State<FormDialogWidget> createState() => _FormDialogWidgetState();
}

class _FormDialogWidgetState extends State<FormDialogWidget> {
  final controller = Modular.get<FormDialogStore>();

  @override
  void initState() {
    super.initState();
    if (widget.cargo != null) {
      controller.setCargo(widget.cargo!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
          key: controller.formController.key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                initialValue: widget.cargo?.nome,
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
                initialValue: widget.cargo?.descricao,
              ),
            ],
          )),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextButton(
          onPressed: () {
            if (widget.labelButton.contains("Salvar")) {
              controller.save(context);
            } else {
              controller.update(context);
            }
          },
          child: Text(widget.labelButton),
        ),
      ],
    );
  }
}
