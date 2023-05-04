import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';
import 'package:oanse/app/shared/model/leadership/leadership_model.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/utils/form_controller.dart';

part 'login_leadership_controller.g.dart';

class LoginLeadershipController = LoginLeadershipControllerBase
    with _$LoginLeadershipController;

abstract class LoginLeadershipControllerBase with Store {
  LoginLeadershipControllerBase(this._authService);
  final IAuthHiveService _authService;
  final FormController formController = FormController();

  @observable
  String _userName = "";

  @action
  setUserName(String value) => _userName = value;

  String get userName => _userName;

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

    //var isNetwork = await NetworkCheck.check();

    if (formController.validate()) {
      //if (isNetwork) {
      var data = LeadershipModel(
        id: 0,
        name: "",
        userName: userName,
        password: senha,
      );
      var result = await _authService.login(data);
      result.when(
        (success) async {
          await _salvarDadosUsuarioLocal(success);

          Modular.to.pushReplacementNamed('$routeHomeLeadership/',
              arguments: success);
        },
        (error) {
          AsukaSnackbar.alert(error.toString()).show();
        },
      );
      /*} else {
        AsukaSnackbar.alert("Sem conexão de internet").show();
      }*/
    }

    EasyLoading.dismiss();
  }

  Future<void> _salvarDadosUsuarioLocal(LeadershipModel data) async {
    await _authService.setDataUserLocal(data);
  }
}
