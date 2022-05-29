import 'package:asuka/asuka.dart' as asuka;
import 'package:flutter/material.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:oanse/app/shared/utils/form_controller.dart';

import '../../model/cargo.dart';
import '../../services/interfaces/cargo_service_interface.dart';

part 'add_store.g.dart';

class AddStore = AddStoreBase with _$AddStore;

abstract class AddStoreBase with Store {
  AddStoreBase(this._service);
  final Cargo cargo = Cargo();
  final FormController formController = FormController();
  final ICargoService _service;

  Future<void> save() async {
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
        EasyLoading.dismiss().then((value) => Modular.to.pop());
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
}
