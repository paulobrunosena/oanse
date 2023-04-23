import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/model/club/club_model.dart';
import '../../shared/services/interfaces/club_service_interface.dart';

part 'club_controller.g.dart';

class ClubController = ClubControllerBase with _$ClubController;

abstract class ClubControllerBase with Store {
  ClubControllerBase(this._clubService) {
    allClubs();
  }
  final IClubService _clubService;
  ObservableList<ClubModel> clubs = ObservableList<ClubModel>();

  Future<void> register() async {
    EasyLoading.show(status: "Realizando cadastro, aguarde...");
    var result = await _clubService.allClubs();

    result.when((success) {
      EasyLoading.dismiss();
      Modular.to.pop();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> allClubs() async {
    EasyLoading.show(
        status: "Buscando todos os clubes cadastrados, aguarde...");
    var result = await _clubService.allClubs();
    clubs.clear();
    result.when((success) {
      clubs.addAll(success);
      EasyLoading.dismiss();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }
}
