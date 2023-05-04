import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/user_service_interface.dart';

part 'home_leadership_controller.g.dart';

class HomeLeadershipController = HomeLeadershipControllerBase
    with _$HomeLeadershipController;

abstract class HomeLeadershipControllerBase with Store {
  HomeLeadershipControllerBase(
    this._authService,
    this._authHiveService,
    this._userService,
  );
  final IAuthService _authService;
  final IAuthHiveService _authHiveService;
  final IUserService _userService;

  Future<void> logout() async {
    EasyLoading.show(status: "Realizando logout, aguarde...");
    var result = await _authService.logout();

    result.when((success) async {
      debugPrint("Message logout: ${success.message}");
      EasyLoading.dismiss();
      await _authService.removeDataUserLocal();
      Modular.to.pushNamedAndRemoveUntil(
          '$routeLogin/', ModalRoute.withName(routeLogin));
    }, (error) async {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
      await _authService.removeDataUserLocal();
      Modular.to.pushNamedAndRemoveUntil(
          '$routeLogin/', ModalRoute.withName(routeLogin));
    });
  }

  Future<void> logoutHive() async {
    EasyLoading.show(status: "Realizando logout, aguarde...");
    await _authHiveService.removeDataUserLocal();
    EasyLoading.dismiss();
    Modular.to.pushReplacementNamed('$routeLoginLeadership/');
  }

  Future<void> allUsers() async {
    EasyLoading.show(status: "Buscando todos os usuários, aguarde...");
    var result = await _userService.allUsers();

    result.when((success) {
      for (var user in success) {
        user.email;
        user.username;
        user.publicId;
        user.publicId;
        debugPrint(
            "email: ${user.email}, username: ${user.username}, publicId: ${user.publicId}");
      }
      EasyLoading.dismiss();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }
}
