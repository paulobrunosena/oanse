// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cargo_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CargoStore on CargoStoreBase, Store {
  late final _$loadingListAtom =
      Atom(name: 'CargoStoreBase.loadingList', context: context);

  @override
  bool get loadingList {
    _$loadingListAtom.reportRead();
    return super.loadingList;
  }

  @override
  set loadingList(bool value) {
    _$loadingListAtom.reportWrite(value, super.loadingList, () {
      super.loadingList = value;
    });
  }

  late final _$isInitialAtom =
      Atom(name: 'CargoStoreBase.isInitial', context: context);

  @override
  bool get isInitial {
    _$isInitialAtom.reportRead();
    return super.isInitial;
  }

  @override
  set isInitial(bool value) {
    _$isInitialAtom.reportWrite(value, super.isInitial, () {
      super.isInitial = value;
    });
  }

  @override
  String toString() {
    return '''
loadingList: ${loadingList},
isInitial: ${isInitial}
    ''';
  }
}
