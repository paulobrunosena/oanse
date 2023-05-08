import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import '../../shared/constants.dart';
import '../../shared/model/club/club_model.dart';
import '../../shared/model/leadership/leadership_model.dart';
import '../../shared/model/role/role_model.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/leadership_service_interface.dart';
import '../../shared/utils/sequence.dart';

part 'splash_controller.g.dart';

class SplashController = SplashControllerBase with _$SplashController;

abstract class SplashControllerBase with Store {
  final IAuthService _authService;
  final IAuthHiveService _authHiveService;
  final ILeadershipService _leadershipService;

  SplashControllerBase(
    this._authService,
    this._authHiveService,
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

  Future<void> redirectPageLoginLeadership() async {
    await initHive();
    var result = _authHiveService.getDataUserLocal();
    if (result == null) {
      Modular.to.pushReplacementNamed('$routeLogin/');
    } else {
      Modular.to.pushReplacementNamed('$routeHome/', arguments: result);
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
        Modular.to
            .pushReplacementNamed('$routeHome/', arguments: leadershipSelect);
      },
      (error) {
        EasyLoading.dismiss();
        AsukaSnackbar.alert(error.toString()).show();
      },
    );
  }

  Future<void> initHive() async {
    Box<LeadershipModel> leadershipBox =
        Hive.box<LeadershipModel>(boxLeadership);
    Box<ClubModel> clubBox = Hive.box<ClubModel>(boxClub);
    Box<RoleModel> roleBox = Hive.box<RoleModel>(boxRole);

    if (leadershipBox.isEmpty) {
      int idLeadership = await Sequence.idGenerator();
      await leadershipBox.put(
        idLeadership,
        LeadershipModel(
            id: idLeadership,
            name: "Paulo Ricardo Martins",
            password: "oanse2023",
            userName: "paulomartins",
            club: 3,
            role: 2),
      );
    }
    if (clubBox.isEmpty) {
      List<ClubModel> listClub = [
        ClubModel(
          id: 1,
          name: "Ursinho",
          entryAge: 4,
          leaveAge: 6,
        ),
        ClubModel(
          id: 2,
          name: "Faísca",
          entryAge: 6,
          leaveAge: 9,
        ),
        ClubModel(
          id: 3,
          name: "Flama",
          entryAge: 9,
          leaveAge: 11,
        ),
        ClubModel(
          id: 4,
          name: "Tocha",
          entryAge: 11,
          leaveAge: 13,
        ),
        ClubModel(
          id: 5,
          name: "JV",
          entryAge: 13,
          leaveAge: 15,
        ),
        ClubModel(
          id: 6,
          name: "VQ7",
          entryAge: 15,
          leaveAge: 19,
        ),
      ];
      await clubBox.addAll(listClub);
    }

    if (roleBox.isEmpty) {
      List<RoleModel> listRole = [
        RoleModel(
          id: 1,
          name: "Líder de clube",
          description:
              "Líder responsável por passar as seções dos manuais e evangelizar as crianças sobre sua responsabilidade",
        ),
        RoleModel(
          id: 2,
          name: "Diretor de clube",
          description: "Responsável por líderar os líderes de clube",
        ),
        RoleModel(
          id: 3,
          name: "Secretária geral",
          description: "Responsável por gerir material do oanse",
        ),
        RoleModel(
          id: 4,
          name: "Diretor geral",
          description: "Responsável por gerir o oanse na igreja local",
        ),
      ];
      await roleBox.addAll(listRole);
    }
  }
}
