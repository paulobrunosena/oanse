// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CargoStore on CargoStoreBase, Store {
  late final _$valueAtom = Atom(name: 'CargoStoreBase.value', context: context);

  @override
  int get value {
    _$valueAtom.reportRead();
    return super.value;
  }

  @override
  set value(int value) {
    _$valueAtom.reportWrite(value, super.value, () {
      super.value = value;
    });
  }

  late final _$CargoStoreBaseActionController =
      ActionController(name: 'CargoStoreBase', context: context);

  @override
  void increment() {
    final _$actionInfo = _$CargoStoreBaseActionController.startAction(
        name: 'CargoStoreBase.increment');
    try {
      return super.increment();
    } finally {
      _$CargoStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
value: ${value}
    ''';
  }
}
