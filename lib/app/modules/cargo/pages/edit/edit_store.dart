import 'package:asuka/asuka.dart' as asuka;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../shared/utils/form_controller.dart';
import '../../model/cargo.dart';
import '../../services/interfaces/cargo_service_interface.dart';

part 'edit_store.g.dart';

class EditStore = EditStoreBase with _$EditStore;

abstract class EditStoreBase with Store {
  EditStoreBase(this._service);

  FormController formController = FormController();
  final ICargoService _service;

  Cargo cargo = Cargo();

  Future<void> update() async {
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
        EasyLoading.dismiss().then((value) => Modular.to.pop(true));
      });
    }
  }

  Future<void> delete() async {
    if (formController.validate()) {
      EasyLoading.show(status: "Salvando dados, aguarde...");

      var result = await _service.delete(cargo.idCargo!);
      result.fold((failure) {
        EasyLoading.dismiss();
        asuka.showSnackBar(SnackBar(
            content: Text(failure.message!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3)));
      }, (retorno) {
        asuka.showSnackBar(const SnackBar(
            content: Text("Registro deletado com sucesso"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3)));
        EasyLoading.dismiss().then((value) => Modular.to.pop(true));
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
