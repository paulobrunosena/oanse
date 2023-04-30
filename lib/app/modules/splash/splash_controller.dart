import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/leadership_service_interface.dart';

part 'splash_controller.g.dart';

class SplashController = SplashControllerBase with _$SplashController;

abstract class SplashControllerBase with Store {
  final IAuthService _authService;
  final ILeadershipService _leadershipService;

  SplashControllerBase(
    this._authService,
    this._leadershipService,
  );

  Future<void> redirectPage() async {
    var result = await _authService.getDataUserLocal();
    if (result == null) {
      Modular.to.pushReplacementNamed('$routeLogin/');
    } else {
      debugPrint("token do sharedpreferences: ${result.token}");
      if (_authService.getToken() == null) {
        debugPrint("token vem nulo");
      } else {
        debugPrint("Valor do token inicial é ${_authService.getToken()}");
      }
      _authService.setToken(result.token);
      debugPrint("Valor do token agora de fato é ${_authService.getToken()}");
      Modular.to.pushReplacementNamed('$routeHome/');
    }
  }

  Future<void> redirectPageLeadership() async {
    EasyLoading.show(status: "Selecionando líder, aguarde...");
    var result = await _leadershipService.allLeaderships();
    result.when(
      (success) async {
        LeadershipModel? leadershipSelect;
        for (LeadershipModel leadership in success) {
          if (leadership.userName == 'pauloricardo') {
            leadershipSelect = leadership;
            break;
          }
        }
        EasyLoading.dismiss();
        Modular.to.pushReplacementNamed('$routeHomeLeadership/',
            arguments: leadershipSelect);
      },
      (error) {
        EasyLoading.dismiss();
        AsukaSnackbar.alert(error.toString()).show();
      },
    );
  }
}
