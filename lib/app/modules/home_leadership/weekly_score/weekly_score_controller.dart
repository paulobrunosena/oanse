import 'package:asuka/asuka.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/model/meeting/meeting_model.dart';
import '../../../shared/services/interfaces/meeting_service_interface.dart';

part 'weekly_score_controller.g.dart';

class WeeklyScoreController = WeeklyScoreControllerBase
    with _$WeeklyScoreController;

abstract class WeeklyScoreControllerBase with Store {
  WeeklyScoreControllerBase(this._serviceMeeting) {
    allMeetings();
  }

  final IMeetingService _serviceMeeting;
  ObservableList<MeetingModel> meetings = ObservableList<MeetingModel>();

  Future<void> allMeetings() async {
    EasyLoading.show(status: "Buscando as reuniões do clube Oanse, aguarde...");
    var result = await _serviceMeeting.allMeeting();
    meetings.clear();
    result.when((success) {
      meetings.addAll(success);
      EasyLoading.dismiss();
    }, (error) {
      EasyLoading.dismiss();
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> save() async {}
}
