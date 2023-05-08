// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreModelAdapter extends TypeAdapter<ScoreModel> {
  @override
  final int typeId = 6;

  @override
  ScoreModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreModel(
      id: fields[0] as int?,
      quantity: fields[1] as int,
      meetingId: fields[2] as int?,
      scoreItemId: fields[3] as int?,
      leadershipId: fields[4] as int?,
      oansistId: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.meetingId)
      ..writeByte(3)
      ..write(obj.scoreItemId)
      ..writeByte(4)
      ..write(obj.leadershipId)
      ..writeByte(5)
      ..write(obj.oansistId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ScoreModel on ScoreModelBase, Store {
  late final _$quantityAtom =
      Atom(name: 'ScoreModelBase.quantity', context: context);

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

  late final _$ScoreModelBaseActionController =
      ActionController(name: 'ScoreModelBase', context: context);

  @override
  void setQuantity(int newValue) {
    final _$actionInfo = _$ScoreModelBaseActionController.startAction(
        name: 'ScoreModelBase.setQuantity');
    try {
      return super.setQuantity(newValue);
    } finally {
      _$ScoreModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
quantity: ${quantity}
    ''';
  }
}
