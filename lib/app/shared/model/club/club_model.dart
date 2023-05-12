import 'dart:convert';

import 'package:hive/hive.dart';

part 'club_model.g.dart';

List<ClubModel> clubModelFromJson(List<dynamic> str) =>
    List<ClubModel>.from(str.map((x) => ClubModel.fromJson(x)));

String clubModelToJson(List<ClubModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@HiveType(typeId: 0)
class ClubModel {
  ClubModel({
    required this.leaveAge,
    required this.id,
    required this.name,
    required this.entryAge,
  });
  @HiveField(0)
  int id;
  @HiveField(1)
  String name;
  @HiveField(2)
  int entryAge;
  @HiveField(3)
  int leaveAge;

  factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
        leaveAge: json['leave_age'],
        id: json['id'],
        name: json['name'],
        entryAge: json['entry_age'],
      );

  Map<String, dynamic> toJson() => {
        'leave_age': leaveAge,
        'id': id,
        'name': name,
        'entry_age': entryAge,
      };
}
