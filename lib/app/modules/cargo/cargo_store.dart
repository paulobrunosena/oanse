import 'package:asuka/asuka.dart' as asuka;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobx/mobx.dart';
import 'package:oanse/app/modules/cargo/model/user.dart';

import 'model/cargo.dart';
import 'services/interfaces/cargo_service_interface.dart';

part 'cargo_store.g.dart';

class CargoStore = CargoStoreBase with _$CargoStore;

abstract class CargoStoreBase with Store {
  CargoStoreBase(this._service);

  final ICargoService _service;

  @observable
  bool loadingList = false;

  @observable
  bool isInitial = true;

  ObservableList<Cargo> listCargo = ObservableList<Cargo>();

  ObservableList<User> listUser = ObservableList<User>();

  Future<void> list() async {
    loadingList = true;
    listCargo.clear();
    EasyLoading.show(status: "Carregando dados, aguarde...");

    isInitial = false;
    var result = await _service.list();

    result.fold((failure) {
      EasyLoading.dismiss();
      asuka.showSnackBar(SnackBar(
          content: Text(failure.message!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3)));
    }, (list) {
      listCargo.addAll(list ?? []);
      EasyLoading.dismiss();
    });

    loadingList = false;
  }

  Future<void> listUsers() async {
    loadingList = true;
    listUser.clear();
    EasyLoading.show(status: "Carregando dados, aguarde...");

    isInitial = false;
    var result = await _service.listUser();

    result.fold((failure) {
      EasyLoading.dismiss();
      asuka.showSnackBar(SnackBar(
          content: Text(failure.message!),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3)));
    }, (list) {
      listUser.addAll(list ?? []);
      EasyLoading.dismiss();
    });

    loadingList = false;
  }
}
