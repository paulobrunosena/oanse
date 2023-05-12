// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_score_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WeeklyScoreController on WeeklyScoreControllerBase, Store {
  Computed<bool>? _$showScoreItemsComputed;

  @override
  bool get showScoreItems =>
      (_$showScoreItemsComputed ??= Computed<bool>(() => super.showScoreItems,
              name: 'WeeklyScoreControllerBase.showScoreItems'))
          .value;

  late final _$isLoadedAtom =
      Atom(name: 'WeeklyScoreControllerBase.isLoaded', context: context);

  @override
  bool? get isLoaded {
    _$isLoadedAtom.reportRead();
    return super.isLoaded;
  }

  @override
  set isLoaded(bool? value) {
    _$isLoadedAtom.reportWrite(value, super.isLoaded, () {
      super.isLoaded = value;
    });
  }

  late final _$positionGamesAtom =
      Atom(name: 'WeeklyScoreControllerBase.positionGames', context: context);

  @override
  int? get positionGames {
    _$positionGamesAtom.reportRead();
    return super.positionGames;
  }

  @override
  set positionGames(int? value) {
    _$positionGamesAtom.reportWrite(value, super.positionGames, () {
      super.positionGames = value;
    });
  }

  late final _$positionGamesAuxAtom = Atom(
      name: 'WeeklyScoreControllerBase.positionGamesAux', context: context);

  @override
  int? get positionGamesAux {
    _$positionGamesAuxAtom.reportRead();
    return super.positionGamesAux;
  }

  @override
  set positionGamesAux(int? value) {
    _$positionGamesAuxAtom.reportWrite(value, super.positionGamesAux, () {
      super.positionGamesAux = value;
    });
  }

  late final _$selectMeetingAtom =
      Atom(name: 'WeeklyScoreControllerBase.selectMeeting', context: context);

  @override
  MeetingModel? get selectMeeting {
    _$selectMeetingAtom.reportRead();
    return super.selectMeeting;
  }

  @override
  set selectMeeting(MeetingModel? value) {
    _$selectMeetingAtom.reportWrite(value, super.selectMeeting, () {
      super.selectMeeting = value;
    });
  }

  late final _$selectOansistAtom =
      Atom(name: 'WeeklyScoreControllerBase.selectOansist', context: context);

  @override
  OansistModel? get selectOansist {
    _$selectOansistAtom.reportRead();
    return super.selectOansist;
  }

  @override
  set selectOansist(OansistModel? value) {
    _$selectOansistAtom.reportWrite(value, super.selectOansist, () {
      super.selectOansist = value;
    });
  }

  late final _$loadingWidgetsAtom =
      Atom(name: 'WeeklyScoreControllerBase.loadingWidgets', context: context);

  @override
  bool get loadingWidgets {
    _$loadingWidgetsAtom.reportRead();
    return super.loadingWidgets;
  }

  @override
  set loadingWidgets(bool value) {
    _$loadingWidgetsAtom.reportWrite(value, super.loadingWidgets, () {
      super.loadingWidgets = value;
    });
  }

  late final _$_totalScoreAtom =
      Atom(name: 'WeeklyScoreControllerBase._totalScore', context: context);

  @override
  int get _totalScore {
    _$_totalScoreAtom.reportRead();
    return super._totalScore;
  }

  @override
  set _totalScore(int value) {
    _$_totalScoreAtom.reportWrite(value, super._totalScore, () {
      super._totalScore = value;
    });
  }

  late final _$WeeklyScoreControllerBaseActionController =
      ActionController(name: 'WeeklyScoreControllerBase', context: context);

  @override
  void setIsLoaded(bool? newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setIsLoaded');
    try {
      return super.setIsLoaded(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPositionGames(int? newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setPositionGames');
    try {
      return super.setPositionGames(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setPositionGamesAux(int? newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setPositionGamesAux');
    try {
      return super.setPositionGamesAux(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelectMeeting(MeetingModel? newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setSelectMeeting');
    try {
      return super.setSelectMeeting(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSelectOansist(OansistModel? newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setSelectOansist');
    try {
      return super.setSelectOansist(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoadingWidgets(bool newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.setLoadingWidgets');
    try {
      return super.setLoadingWidgets(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void incrementTotalScore(int newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.incrementTotalScore');
    try {
      return super.incrementTotalScore(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void decrementTotalScore(int newValue) {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.decrementTotalScore');
    try {
      return super.decrementTotalScore(newValue);
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetTotalScore() {
    final _$actionInfo = _$WeeklyScoreControllerBaseActionController
        .startAction(name: 'WeeklyScoreControllerBase.resetTotalScore');
    try {
      return super.resetTotalScore();
    } finally {
      _$WeeklyScoreControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoaded: ${isLoaded},
positionGames: ${positionGames},
positionGamesAux: ${positionGamesAux},
selectMeeting: ${selectMeeting},
selectOansist: ${selectOansist},
loadingWidgets: ${loadingWidgets},
showScoreItems: ${showScoreItems}
    ''';
  }
}
