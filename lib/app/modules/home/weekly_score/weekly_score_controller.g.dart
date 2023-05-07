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
  String toString() {
    return '''
selectMeeting: ${selectMeeting},
selectOansist: ${selectOansist},
loadingWidgets: ${loadingWidgets},
showScoreItems: ${showScoreItems}
    ''';
  }
}
