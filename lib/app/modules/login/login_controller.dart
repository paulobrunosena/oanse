import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/model/login/login_model.dart';
import '../../shared/model/login/login_request.dart';
import '../../shared/model/login/login_response.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/utils/form_controller.dart';
import '../../shared/utils/network_check.dart';

part 'login_controller.g.dart';

class LoginController = LoginControllerBase with _$LoginController;

abstract class LoginControllerBase with Store {
  LoginControllerBase(this._authService);
  final IAuthService _authService;
  final FormController formController = FormController();

  @observable
  String _email = "";

  @action
  setEmail(String value) => _email = value;

  String get email => _email;

  @observable
  String _senha = "";

  @action
  void setSenha(String value) => _senha = value;

  String get senha => _senha;

  @observable
  bool senhaVisible = false;

  @action
  void toggleSenhaVisibility() => senhaVisible = !senhaVisible;

  Future<void> login() async {
    EasyLoading.show(status: "Realizando login, aguarde...");

    var isNetwork = await NetworkCheck.check();

    if (formController.validate()) {
      if (isNetwork) {
        var requestLogin = LoginRequest(
          email: email,
          password: senha,
        );
        var result = await _authService.login(requestLogin);
        result.when(
          (success) async {
            await _salvarDadosUsuarioLocal(success);
            Modular.to.pushReplacementNamed('$routeHome/');
          },
          (error) {
            AsukaSnackbar.alert(error.toString()).show();
          },
        );
      } else {
        AsukaSnackbar.alert("Sem conexão de internet").show();
      }
    }

    EasyLoading.dismiss();
  }

  Future<void> _salvarDadosUsuarioLocal(LoginResponse result) async {
    LoginModel data = LoginModel(
      email: email,
    );
    data.setToken(result.authorization);
    await _authService.saveDadosUsuarioLocal(data);
  }
}
