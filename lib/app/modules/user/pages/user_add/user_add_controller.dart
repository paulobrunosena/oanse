import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../../../shared/services/interfaces/user_service_interface.dart';
import '../../../../shared/utils/form_controller.dart';

part 'user_add_controller.g.dart';

class UserAddController = UserAddControllerBase with _$UserAddController;

abstract class UserAddControllerBase with Store {
  UserAddControllerBase(this._userService);

  final IUserService _userService;
  final FormController formController = FormController();
  String? userName;
  String? email;
  String? password;

  Future<void> register() async {
    if (formController.validate()) {
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
  }
}
