import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';
import 'package:oanse/app/modules/home_leadership/weekly_score/store/score_model_store.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import '../../../shared/model/meeting/meeting_model.dart';
import '../../../shared/model/oansist/oansist_model.dart';
import '../../../shared/model/score/score_model.dart';
import '../../../shared/model/score_item/score_item_model.dart';
import '../../../shared/services/interfaces/meeting_service_interface.dart';
import '../../../shared/services/interfaces/oansist_service_interface.dart';
import '../../../shared/services/interfaces/score_item_service_interface.dart';

part 'weekly_score_controller.g.dart';

class WeeklyScoreController = WeeklyScoreControllerBase
    with _$WeeklyScoreController;

abstract class WeeklyScoreControllerBase with Store {
  WeeklyScoreControllerBase(
    this._serviceMeeting,
    this._serviceOansist,
    this._serviceScoreItem,
  );

  final IMeetingService _serviceMeeting;
  final IOansistService _serviceOansist;
  final IScoreItemService _serviceScoreItem;
  ObservableList<MeetingModel> meetings = ObservableList<MeetingModel>();
  ObservableList<OansistModel> oansists = ObservableList<OansistModel>();
  ObservableList<ScoreItemModel> scoreItems = ObservableList<ScoreItemModel>();
  ObservableList<ScoreModelStore> scoresStore =
      ObservableList<ScoreModelStore>();
  late LeadershipModel leadership;

  NumberFormat formatter = NumberFormat('###,###,###');

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
  int _totalScore = 0;

  get totalScore => formatter.format(_totalScore);

  @action
  void incrementTotalScore(int newValue) {
    _totalScore = _totalScore + newValue;
  }

  @action
  void decrementTotalScore(int newValue) {
    _totalScore = _totalScore - newValue;
  }

  initWidgets(LeadershipModel leadershipModel) {
    leadership = leadershipModel;
    selectMeeting = null;
    selectOansist = null;
    _totalScore = 0;
    setLoadingWidgets(true);
    Future.wait([
      loadMeetings(),
      loadOansists(),
      loadScoreItemsHive(), //loadScoreItems(),
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
    var result = await _serviceOansist.clubOansist(leadership);
    oansists.clear();
    result.when((success) {
      oansists.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadScoreItems() async {
    var result = await _serviceScoreItem.allScoreItems();
    scoreItems.clear();
    scoresStore.clear();
    result.when((success) {
      scoreItems.addAll(success);
      for (ScoreItemModel scoreItem in scoreItems) {
        var scoreModel = ScoreModel(
          quantity: "0",
          meetingId: selectMeeting?.id,
          leadershipId: leadership.id,
          oansistId: selectOansist?.id,
          scoreItemId: scoreItem.id,
        );
        ScoreModelStore store = ScoreModelStore(scoreModel);
        scoresStore.add(store);
      }
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadScoreItemsHive() async {
    var result = _serviceScoreItem.allScoreItemsHive();
    scoreItems.clear();
    scoresStore.clear();
    result.when((success) {
      scoreItems.addAll(success);
      for (ScoreItemModel scoreItem in scoreItems) {
        var scoreModel = ScoreModel(
          quantity: "0",
          meetingId: selectMeeting?.id,
          leadershipId: leadership.id,
          oansistId: selectOansist?.id,
          scoreItemId: scoreItem.id,
        );
        ScoreModelStore store = ScoreModelStore(scoreModel);
        scoresStore.add(store);
      }
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
