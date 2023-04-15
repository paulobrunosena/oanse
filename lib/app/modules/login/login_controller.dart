import 'package:mobx/mobx.dart';

import '../../shared/utils/form_controller.dart';

part 'login_controller.g.dart';

class LoginController = LoginControllerBase with _$LoginController;

abstract class LoginControllerBase with Store {
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
}
