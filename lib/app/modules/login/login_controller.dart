import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/utils/form_controller.dart';

part 'login_controller.g.dart';

class LoginController = LoginControllerBase with _$LoginController;

abstract class LoginControllerBase with Store {
  LoginControllerBase(this._authService);
  final IAuthHiveService _authService;
  final FormController formController = FormController();

  @observable
  String _userName = '';

  @action
  String setUserName(String value) => _userName = value;

  String get userName => _userName;

  @observable
  String _password = '';

  @action
  void setPassword(String value) => _password = value;

  String get password => _password;

  @observable
  bool senhaVisible = false;

  @action
  void toggleSenhaVisibility() => senhaVisible = !senhaVisible;

  Future<void> login() async {
    EasyLoading.show(status: 'Realizando login, aguarde...');
    if (formController.validate()) {
      final result = await _authService.login(userName, password);
      result.when(
        (success) async {
          await _authService.setDataUserLocal(success);
          Modular.to.pushReplacementNamed('$routeHome/', arguments: success);
        },
        (error) {
          AsukaSnackbar.alert(error.toString()).show();
        },
      );
    }

    EasyLoading.dismiss();
  }
}
