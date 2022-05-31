import 'package:asuka/asuka.dart' as asuka;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/utils/form_controller.dart';
import '../model/cargo.dart';
import '../services/interfaces/cargo_service_interface.dart';

part 'form_dialog_store.g.dart';

class FormDialogStore = FormDialogStoreBase with _$FormDialogStore;

abstract class FormDialogStoreBase with Store {
  FormDialogStoreBase(this._service);
  Cargo cargo = Cargo();
  final FormController formController = FormController();
  final ICargoService _service;

  Future<void> save(BuildContext context) async {
    if (formController.validate()) {
      EasyLoading.show(status: "Salvando dados, aguarde...");
      var result = await _service.insert(cargo.toJson());
      result.fold((failure) {
        EasyLoading.dismiss();
        asuka.showSnackBar(SnackBar(
            content: Text(failure.message!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3)));
      }, (retorno) {
        asuka.showSnackBar(const SnackBar(
            content: Text("Registro salvo com sucesso"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3)));
        EasyLoading.dismiss().then((value) => Navigator.pop(context, true));
      });
    }
  }

  Future<void> update(BuildContext context) async {
    if (formController.validate()) {
      EasyLoading.show(status: "Salvando dados, aguarde...");

      var result = await _service.update(cargo.idCargo!, cargo.toJson());
      result.fold((failure) {
        EasyLoading.dismiss();
        asuka.showSnackBar(SnackBar(
            content: Text(failure.message!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3)));
      }, (retorno) {
        asuka.showSnackBar(const SnackBar(
            content: Text("Registro editado com sucesso"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3)));
        EasyLoading.dismiss().then((value) => Navigator.pop(context, true));
      });
    }
  }

  String? validateNome(String? value) {
    if (value == null || value.isEmpty) return "Nome obrigatório";
    return null;
  }

  String? validateDescricao(String? value) {
    if (value == null || value.isEmpty) return "Descrição obrigatória";
    return null;
  }

  setCargo(Cargo newValue) {
    cargo = newValue;
  }
}
