// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_model_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ScoreModelStore on ScoreModelStoreBase, Store {
  late final _$quantityAtom =
      Atom(name: 'ScoreModelStoreBase.quantity', context: context);

  @override
  int get quantity {
    _$quantityAtom.reportRead();
    return super.quantity;
  }

  @override
  set quantity(int value) {
    _$quantityAtom.reportWrite(value, super.quantity, () {
      super.quantity = value;
    });
  }

  late final _$ScoreModelStoreBaseActionController =
      ActionController(name: 'ScoreModelStoreBase', context: context);

  @override
  dynamic setQuantity(int newValue) {
    final _$actionInfo = _$ScoreModelStoreBaseActionController.startAction(
        name: 'ScoreModelStoreBase.setQuantity');
    try {
      return super.setQuantity(newValue);
    } finally {
      _$ScoreModelStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
quantity: ${quantity}
    ''';
  }
}
