import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import '../../../shared/model/meeting/meeting_model.dart';
import '../../../shared/model/oansist/oansist_model.dart';
import '../../../shared/services/interfaces/meeting_service_interface.dart';
import '../../../shared/services/interfaces/oansist_service_interface.dart';

part 'weekly_score_controller.g.dart';

class WeeklyScoreController = WeeklyScoreControllerBase
    with _$WeeklyScoreController;

abstract class WeeklyScoreControllerBase with Store {
  WeeklyScoreControllerBase(this._serviceMeeting, this._serviceOansist);

  final IMeetingService _serviceMeeting;
  final IOansistService _serviceOansist;
  ObservableList<MeetingModel> meetings = ObservableList<MeetingModel>();
  ObservableList<OansistModel> oansists = ObservableList<OansistModel>();
  late LeadershipModel leadership;

  @observable
  MeetingModel? selectMeeting;

  @action
  void setSelectMeeting(MeetingModel? newValue) {
    selectMeeting = newValue;
  }

  @observable
  OansistModel? selectOansist;

  @action
  void setSelectOansist(OansistModel? newValue) {
    selectOansist = newValue;
  }

  @observable
  bool loadingWidgets = false;

  @action
  void setLoadingWidgets(bool newValue) {
    loadingWidgets = newValue;
  }

  @observable
  int totalScore = 0;

  @action
  void setTotalScore(int newValue) {
    totalScore = newValue;
  }

  initWidgets(LeadershipModel leadershipModel) {
    leadership = leadershipModel;
    setLoadingWidgets(true);
    Future.wait([
      loadMeetings(),
      loadOansists(),
    ]).then((value) async {
      setLoadingWidgets(false);
    });
  }

  Future<void> loadMeetings() async {
    var result = await _serviceMeeting.allMeeting();
    meetings.clear();
    result.when((success) {
      meetings.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadOansists() async {
    var result = await _serviceOansist.allOansist();
    oansists.clear();
    result.when((success) {
      oansists.addAll(success
          .where((element) => element.clubId == leadership.club)
          .toList());
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  showMeetings() {
    Asuka.showModalBottomSheet(builder: (BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 10,
          ),
          const Text(
            "Selecione uma data",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          ListView.separated(
            shrinkWrap: true,
            itemCount: meetings.length,
            itemBuilder: (_, index) {
              MeetingModel meeting = meetings[index];

              return ListTile(
                title: Text(meeting.dataFormatada),
                onTap: () {
                  Navigator.pop(context);
                  setSelectMeeting(meeting);
                },
              );
            },
            separatorBuilder: (_, __) {
              return const Divider();
            },
          )
        ],
      );
    });
  }

  showOansists() {
    Asuka.showModalBottomSheet(
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              "Selecione um oansista",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            ListView.separated(
              shrinkWrap: true,
              itemCount: oansists.length,
              itemBuilder: (_, index) {
                OansistModel oansist = oansists[index];

                return ListTile(
                  title: Text(oansist.name ?? ""),
                  onTap: () {
                    Navigator.pop(context);
                    setSelectOansist(oansist);
                  },
                );
              },
              separatorBuilder: (_, __) {
                return const Divider();
              },
            )
          ],
        );
      },
    );
  }

  Future<void> save() async {}
}
