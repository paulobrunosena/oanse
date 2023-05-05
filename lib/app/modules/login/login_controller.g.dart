// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_controller.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LoginController on LoginControllerBase, Store {
  late final _$_userNameAtom =
      Atom(name: 'LoginControllerBase._userName', context: context);

  @override
  String get _userName {
    _$_userNameAtom.reportRead();
    return super._userName;
  }

  @override
  set _userName(String value) {
    _$_userNameAtom.reportWrite(value, super._userName, () {
      super._userName = value;
    });
  }

  late final _$_senhaAtom =
      Atom(name: 'LoginControllerBase._senha', context: context);

  @override
  String get _senha {
    _$_senhaAtom.reportRead();
    return super._senha;
  }

  @override
  set _senha(String value) {
    _$_senhaAtom.reportWrite(value, super._senha, () {
      super._senha = value;
    });
  }

  late final _$senhaVisibleAtom =
      Atom(name: 'LoginControllerBase.senhaVisible', context: context);

  @override
  bool get senhaVisible {
    _$senhaVisibleAtom.reportRead();
    return super.senhaVisible;
  }

  @override
  set senhaVisible(bool value) {
    _$senhaVisibleAtom.reportWrite(value, super.senhaVisible, () {
      super.senhaVisible = value;
    });
  }

  late final _$LoginControllerBaseActionController =
      ActionController(name: 'LoginControllerBase', context: context);

  @override
  dynamic setUserName(String value) {
    final _$actionInfo = _$LoginControllerBaseActionController.startAction(
        name: 'LoginControllerBase.setUserName');
    try {
      return super.setUserName(value);
    } finally {
      _$LoginControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setSenha(String value) {
    final _$actionInfo = _$LoginControllerBaseActionController.startAction(
        name: 'LoginControllerBase.setSenha');
    try {
      return super.setSenha(value);
    } finally {
      _$LoginControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleSenhaVisibility() {
    final _$actionInfo = _$LoginControllerBaseActionController.startAction(
        name: 'LoginControllerBase.toggleSenhaVisibility');
    try {
      return super.toggleSenhaVisibility();
    } finally {
      _$LoginControllerBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
senhaVisible: ${senhaVisible}
    ''';
  }
}
