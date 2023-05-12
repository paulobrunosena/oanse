import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/services/interfaces/leadership_service_interface.dart';

part 'leadership_controller.g.dart';

class LeadershipController = LeadershipControllerBase
    with _$LeadershipController;

abstract class LeadershipControllerBase with Store {
  LeadershipControllerBase(this._userService) {
    allLeaderships();
  }
  final ILeadershipService _userService;
  ObservableList<LeadershipModel> users = ObservableList<LeadershipModel>();

  Future<void> register() async {
    EasyLoading.show(status: 'Realizando cadastro, aguarde...');
    final result = await _userService.allLeaderships();

    result.when((success) {
      EasyLoading.dismiss();
      Modular.to.pop();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> allLeaderships() async {
    EasyLoading.show(status: 'Buscando todos os usuários, aguarde...');
    final result = await _userService.allLeaderships();
    users.clear();
    result.when((success) {
      users.addAll(success);
      EasyLoading.dismiss();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }
}
