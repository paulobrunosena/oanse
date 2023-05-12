import 'dart:developer';

import 'package:asuka/asuka.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobx/mobx.dart';

import '../../../shared/model/leadership/leadership_model.dart';
import '../../../shared/model/meeting/meeting_model.dart';
import '../../../shared/model/oansist/oansist_model.dart';
import '../../../shared/model/score/score_model.dart';
import '../../../shared/model/score_item/score_item_model.dart';
import '../../../shared/services/interfaces/meeting_service_interface.dart';
import '../../../shared/services/interfaces/oansist_service_interface.dart';
import '../../../shared/services/interfaces/score_item_service_interface.dart';
import '../../../shared/services/interfaces/score_service_interface.dart';
import '../../../shared/utils/sequence.dart';

part 'weekly_score_controller.g.dart';

class WeeklyScoreController = WeeklyScoreControllerBase
    with _$WeeklyScoreController;

abstract class WeeklyScoreControllerBase with Store {
  WeeklyScoreControllerBase(
    this._serviceMeeting,
    this._serviceOansist,
    this._serviceScoreItem,
    this._serviceScore,
  );

  final IMeetingService _serviceMeeting;
  final IOansistService _serviceOansist;
  final IScoreItemService _serviceScoreItem;
  final IScoreService _serviceScore;
  ObservableList<MeetingModel> meetings = ObservableList<MeetingModel>();
  ObservableList<OansistModel> oansists = ObservableList<OansistModel>();
  ObservableList<ScoreItemModel> scoreItems = ObservableList<ScoreItemModel>();
  ObservableList<ScoreItemModel> scoreItemsSports =
      ObservableList<ScoreItemModel>();
  ObservableList<ScoreModel> scores = ObservableList<ScoreModel>();
  ObservableList<ScoreModel> scoresSports = ObservableList<ScoreModel>();
  late LeadershipModel leadership;

  NumberFormat formatter = NumberFormat('###,###,###');

  @readonly
  ScoreItemModel? _scoreItemSportSelected;

  @action
  void setScoreItemSportSelected(ScoreItemModel? newValue) {
    if (_scoreItemSportSelected != null) {
      decrementTotalScore(_scoreItemSportSelected?.points ?? 0);
    }
    _scoreItemSportSelected = newValue;
    incrementTotalScore(_scoreItemSportSelected?.points ?? 0);
    updateScoreSport();
  }

  @observable
  bool? isLoaded;

  @action
  void setIsLoaded(bool? newValue) {
    isLoaded = newValue;
  }

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

  @computed
  bool get showScoreItems => selectMeeting != null && selectOansist != null;

  @observable
  bool loadingWidgets = false;

  @action
  void setLoadingWidgets(bool newValue) {
    loadingWidgets = newValue;
  }

  @observable
  int _totalScore = 0;

  String get totalScore => formatter.format(_totalScore);

  @action
  void incrementTotalScore(int newValue) {
    _totalScore = _totalScore + newValue;
  }

  @action
  void decrementTotalScore(int newValue) {
    _totalScore = _totalScore - newValue;
  }

  @action
  void resetTotalScore() {
    _totalScore = 0;
  }

  Future<void> initWidgets(LeadershipModel leadershipModel) async {
    leadership = leadershipModel;
    setSelectMeeting(null);
    setSelectOansist(null);
    setScoreItemSportSelected(null);
    resetTotalScore();
    setIsLoaded(null);
    setLoadingWidgets(true);
    Future.wait([
      loadMeetings(),
      loadOansists(),
      loadScoreItems().then((value) => loadScoreItemsSports()),
    ]).then((value) async {
      setLoadingWidgets(false);
    });
  }

  Future<void> loadMeetings() async {
    final result = await _serviceMeeting.allMeeting();
    meetings.clear();
    result.when((success) {
      meetings.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadOansists() async {
    final result = await _serviceOansist.clubOansist(leadership.club ?? -1);
    oansists.clear();
    result.when((success) {
      oansists.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadScoreItems() async {
    final result = await _serviceScoreItem.list();
    scoreItems.clear();
    result.when((success) async {
      scoreItems.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadScoreItemsSports() async {
    final result = await _serviceScoreItem.listScoreItemSports();
    scoreItemsSports.clear();
    result.when((success) async {
      log(success.toString());
      for (var i = 0; i < success.length; i++) {
        log(success[i].name ?? '');
      }
      scoreItemsSports.addAll(success);
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> showMeetings() async {
    Asuka.showModalBottomSheet(
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Selecione uma data',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            ListView.separated(
              shrinkWrap: true,
              itemCount: meetings.length,
              itemBuilder: (_, index) {
                final MeetingModel meeting = meetings[index];

                return ListTile(
                  title: Text(meeting.dataFormatada),
                  onTap: () {
                    Navigator.pop(context);
                    setSelectMeeting(meeting);
                    loadDataWeeklyScore();
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

  Future<void> showOansists() async {
    Asuka.showModalBottomSheet(
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Selecione um oansista',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
            ),
            ListView.separated(
              shrinkWrap: true,
              itemCount: oansists.length,
              itemBuilder: (_, index) {
                final OansistModel oansist = oansists[index];

                return ListTile(
                  title: Text(oansist.name ?? ''),
                  onTap: () {
                    Navigator.pop(context);
                    setSelectOansist(oansist);
                    loadDataWeeklyScore();
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

  Future<void> loadDataWeeklyScore() async {
    if (selectMeeting != null && selectOansist != null) {
      loadScore();
      loadScoreSport();
    }
  }

  Future<void> loadScore() async {
    final result =
        await _serviceScore.list(selectMeeting!.id, selectOansist!.id!);

    result.when((listScoreModel) async {
      if (listScoreModel.isEmpty) {
        await initScore();
        resetTotalScore();
        setIsLoaded(false);
      } else {
        scores.clear();
        scores.addAll(listScoreModel);
        loadTotalScore();
        setIsLoaded(_totalScore > 0);
      }
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> loadScoreSport() async {
    final result = await _serviceScore.listScoreSports(
      selectMeeting!.id,
      selectOansist!.id!,
    );

    result.when((listScoreModel) async {
      if (listScoreModel.isEmpty) {
        await initScoreSport();
        resetTotalScore();
        setIsLoaded(false);
      } else {
        scoresSports.clear();
        scoresSports.addAll(listScoreModel);
        loadTotalScore();
        setIsLoaded(_totalScore > 0);
      }
    }, (error) {
      AsukaSnackbar.alert(error.toString()).show();
    });
  }

  Future<void> initScore() async {
    scores.clear();
    for (ScoreItemModel scoreItem in scoreItems) {
      final int idScore = await Sequence.idGenerator();
      final ScoreModel scoreModel = ScoreModel(
        id: idScore,
        quantity: 0,
        meetingId: selectMeeting?.id,
        leadershipId: leadership.id,
        oansistId: selectOansist?.id,
        scoreItemId: scoreItem.id,
      );
      await _serviceScore.put(idScore, scoreModel);
      scores.add(scoreModel);
    }
  }

  Future<void> initScoreSport() async {
    scoresSports.clear();
    for (ScoreItemModel scoreItem in scoreItemsSports) {
      final int idScore = await Sequence.idGenerator();
      final ScoreModel scoreModel = ScoreModel(
        id: idScore,
        quantity: 0,
        meetingId: selectMeeting?.id,
        leadershipId: leadership.id,
        oansistId: selectOansist?.id,
        scoreItemId: scoreItem.id,
      );
      await _serviceScore.put(idScore, scoreModel);
      scoresSports.add(scoreModel);
    }
  }

  void loadTotalScore() {
    resetTotalScore();
    for (ScoreModel item in scores) {
      final ScoreItemModel scoreItem = getScoreItem(item.scoreItemId!);
      final int total = item.quantity * scoreItem.points!;
      incrementTotalScore(total);
      if (scoreItem.isSport) {
        item.quantity > 0;
        setScoreItemSportSelected(scoreItem);
      }
    }

    if (_scoreItemSportSelected == null) {
      setScoreItemSportSelected(getScoreItem(11));
    }
  }

  void updateScoreSport() {
    for (var scoreSport in scoresSports) {
      scoreSport.quantity = 0;
    }

    for (var scoreSport in scoresSports) {
      if (scoreSport.scoreItemId == (_scoreItemSportSelected?.id ?? 0)) {
        scoreSport.quantity = 1;
      }
    }
  }

  ScoreModel? get scoreSportSelected {
    if (_scoreItemSportSelected != null) {
      return scoresSports
          .where(
            (element) => element.scoreItemId == _scoreItemSportSelected!.id,
          )
          .first;
    }

    return null;
  }

  ScoreItemModel getScoreItem(int key) {
    return _serviceScoreItem.get(key)!;
  }

  Future<void> save() async {
    EasyLoading.show(status: 'Salvando dados, aguarde...');
    for (ScoreModel score in scores) {
      final int idScore = score.id!;
      await _serviceScore.put(idScore, score);
    }

    for (ScoreModel score in scoresSports) {
      final int idScore = score.id!;
      await _serviceScore.put(idScore, score);
    }
    setIsLoaded(_totalScore > 0);
    EasyLoading.dismiss();
  }
}
