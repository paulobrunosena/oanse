// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScoreItemModelAdapter extends TypeAdapter<ScoreItemModel> {
  @override
  final int typeId = 3;

  @override
  ScoreItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreItemModel(
      id: fields[0] as int?,
      name: fields[1] as String?,
      description: fields[2] as String?,
      points: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ScoreItemModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.points);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
