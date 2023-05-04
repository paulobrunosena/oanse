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
import '../../shared/model/score_item/score_item_model.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/leadership_service_interface.dart';

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
      Modular.to.pushReplacementNamed('$routeLoginLeadership/');
    } else {
      Modular.to
          .pushReplacementNamed('$routeHomeLeadership/', arguments: result);
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

  Future<void> initHive() async {
    Box<LeadershipModel> leadershipBox =
        Hive.box<LeadershipModel>(boxLeadership);
    Box<ClubModel> clubBox = Hive.box<ClubModel>(boxClub);
    Box<RoleModel> roleBox = Hive.box<RoleModel>(boxRole);
    Box<ScoreItemModel> scoreItemBox = Hive.box<ScoreItemModel>(boxScoreItem);

    if (leadershipBox.isEmpty) {
      await leadershipBox.add(
        LeadershipModel(
            name: "Paulo Ricardo Martins",
            password: "oanse2023",
            userName: "paulomartins",
            id: 2,
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

    if (scoreItemBox.isEmpty) {
      List<ScoreItemModel> listScoreItem = [
        ScoreItemModel(
          id: 1,
          name: "Uniforme",
          description: "Vir devidamente uniformizado",
          points: 5000,
        ),
        ScoreItemModel(
          id: 2,
          name: "Manual",
          description: "Trazer manual",
          points: 20000,
        ),
        ScoreItemModel(
          id: 3,
          name: "Conduta + contagem até 5",
          description: "Manter boa conduta durante a reunião do oanse",
          points: 10000,
        ),
        ScoreItemModel(
          id: 4,
          name: "Bíblia",
          description: "Trazer a bíblia",
          points: 5000,
        ),
        ScoreItemModel(
          id: 5,
          name: "Leitura bíblica",
          description: "Realizar a leitura bíblica diária",
          points: 20000,
        ),
        ScoreItemModel(
          id: 6,
          name: "EBD",
          description: "Frequentar a EBD regularmente",
          points: 5000,
        ),
        ScoreItemModel(
          id: 7,
          name: "Visitante",
          description: "Trazer visitante, independente de clube",
          points: 10000,
        ),
        ScoreItemModel(
          id: 8,
          name: "Seção sem ajuda",
          description: "Passar na seção sem ajuda do líder",
          points: 20000,
        ),
        ScoreItemModel(
          id: 9,
          name: "Seção com ajuda",
          description: "Passar na seção com ajuda do líder",
          points: 10000,
        ),
        ScoreItemModel(
          id: 10,
          name: "Atividade extra",
          description: "Realizar as atividades extras do manual",
          points: 15000,
        ),
        ScoreItemModel(
          id: 11,
          name: "Não participou (Esportes)",
          description: "Não participou (Esportes)",
          points: 0,
        ),
        ScoreItemModel(
          id: 12,
          name: "1º Lugar (Esportes)",
          description: "1º Lugar (Esportes)",
          points: 5000,
        ),
        ScoreItemModel(
          id: 13,
          name: "2º Lugar (Esportes)",
          description: "2º Lugar (Esportes)",
          points: 4000,
        ),
        ScoreItemModel(
          id: 14,
          name: "3º Lugar (Esportes)",
          description: "3º Lugar (Esportes)",
          points: 3000,
        ),
        ScoreItemModel(
          id: 15,
          name: "4º Lugar (Esportes)",
          description: "4º Lugar (Esportes)",
          points: 2000,
        ),
      ];
      await scoreItemBox.addAll(listScoreItem);
    }
  }
}
