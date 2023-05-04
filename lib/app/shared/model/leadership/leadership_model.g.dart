// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leadership_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeadershipModelAdapter extends TypeAdapter<LeadershipModel> {
  @override
  final int typeId = 1;

  @override
  LeadershipModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeadershipModel(
      id: fields[0] as int,
      name: fields[1] as String,
      userName: fields[2] as String,
      password: fields[3] as String,
      club: fields[4] as int?,
      role: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, LeadershipModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.club)
      ..writeByte(5)
      ..write(obj.role);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeadershipModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
