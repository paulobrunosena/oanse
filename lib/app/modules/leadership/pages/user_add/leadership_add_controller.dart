import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../shared/services/interfaces/leadership_service_interface.dart';
import '../../../../shared/utils/form_controller.dart';

part 'leadership_add_controller.g.dart';

class LeadershipAddController = LeadershipAddControllerBase
    with _$LeadershipAddController;

abstract class LeadershipAddControllerBase with Store {
  LeadershipAddControllerBase(this._service);

  final ILeadershipService _service;
  final FormController formController = FormController();
  String? name;
  String? userName;
  String? password;
  int? idClub;
  int? idRole;

  Future<void> register() async {
    if (formController.validate()) {
      EasyLoading.show(status: 'Realizando cadastro, aguarde...');
      final result = await _service.allLeaderships();

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
