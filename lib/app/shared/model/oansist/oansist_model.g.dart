// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'oansist_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OansistModelAdapter extends TypeAdapter<OansistModel> {
  @override
  final int typeId = 5;

  @override
  OansistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OansistModel(
      id: fields[0] as int?,
      name: fields[1] as String?,
      birthDate: fields[2] as DateTime?,
      gender: fields[3] as String?,
      clubId: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, OansistModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.birthDate)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.clubId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OansistModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
