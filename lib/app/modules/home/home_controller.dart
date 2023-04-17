import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';

part 'home_controller.g.dart';

class HomeController = HomeControllerBase with _$HomeController;

abstract class HomeControllerBase with Store {
  HomeControllerBase(this._authService);
  final IAuthService _authService;

  Future<void> logout() async {
    EasyLoading.show(status: "Realizando logout, aguarde...");
    var result = await _authService.logout();

    result.when((success) {
      debugPrint("Message logout: ${success.message}");
      EasyLoading.dismiss();
      Modular.to.pushNamedAndRemoveUntil(
          '$routeLogin/', ModalRoute.withName(routeLogin));
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }
}
