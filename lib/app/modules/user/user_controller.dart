import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/model/user/user_model.dart';
import '../../shared/services/interfaces/user_service_interface.dart';

part 'user_controller.g.dart';

class UserController = UserControllerBase with _$UserController;

abstract class UserControllerBase with Store {
  UserControllerBase(this._userService) {
    allUsers();
  }
  final IUserService _userService;
  ObservableList<User> users = ObservableList<User>();

  Future<void> register() async {
    EasyLoading.show(status: 'Realizando cadastro, aguarde...');
    final result = await _userService.allUsers();

    result.when((success) {
      EasyLoading.dismiss();
      Modular.to.pop();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> allUsers() async {
    EasyLoading.show(status: 'Buscando todos os usuários, aguarde...');
    final result = await _userService.allUsers();
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
