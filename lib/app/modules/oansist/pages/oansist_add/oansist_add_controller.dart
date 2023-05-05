import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:oanse/app/shared/model/oansist/oansist_model.dart';

import '../../../../shared/services/interfaces/oansist_service_interface.dart';
import '../../../../shared/utils/form_controller.dart';

part 'oansist_add_controller.g.dart';

class OansistAddController = OansistAddControllerBase
    with _$OansistAddController;

abstract class OansistAddControllerBase with Store {
  OansistAddControllerBase(this._service);

  final IOansistService _service;
  final FormController formController = FormController();
  String? name;
  String? birthDate;
  int? clubId;
  String? gender;

  Future<void> register() async {
    if (formController.validate()) {
      EasyLoading.show(status: "Realizando cadastro, aguarde...");
      OansistModel data = OansistModel(
          id: -1,
          name: name,
          birthDate: DateTime.now(),
          clubId: 3,
          gender: "M");
      var result = await _service.addOansist(data);

      result.when((success) {
        EasyLoading.dismiss();
        Modular.to.pop();
      }, (error) {
        EasyLoading.dismiss();
        AsukaSnackbar.alert(error.toString()).show();
      });
    }
  }
}
