import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/model/oansist/oansist_model.dart';
import '../../shared/services/interfaces/oansist_service_interface.dart';

part 'oansist_controller.g.dart';

class OansistController = OansistControllerBase with _$OansistController;

abstract class OansistControllerBase with Store {
  OansistControllerBase(this._oansistService) {
    allOansists();
  }
  final IOansistService _oansistService;
  ObservableList<OansistModel> oansists = ObservableList<OansistModel>();

  Future<void> add() async {
    EasyLoading.show(status: "Realizando cadastro, aguarde...");
    OansistModel data = OansistModel(
        name: "Ana Paula", birthDate: "2017-01-10", gender: "F", clubId: 2);
    var result = await _oansistService.addOansist(data);

    result.when((success) {
      EasyLoading.dismiss();
      Modular.to.pop();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> allOansists() async {
    EasyLoading.show(
        status: "Buscando todos os oansistas do clube, aguarde...");
    var result = await _oansistService.allOansist();
    oansists.clear();
    result.when((success) {
      oansists.addAll(success);
      EasyLoading.dismiss();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }
}
