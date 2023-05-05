import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'meeting_model.g.dart';

List<MeetingModel> meetingModelFromJson(List<dynamic> str) =>
    List<MeetingModel>.from(str.map((x) => MeetingModel.fromJson(x)));

String meetingModelToJson(List<MeetingModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@HiveType(typeId: 4)
class MeetingModel {
  MeetingModel({
    required this.id,
    required this.date,
  });
  @HiveField(0)
  int id;
  @HiveField(1)
  DateTime date;

  factory MeetingModel.fromJson(Map<String, dynamic> json) => MeetingModel(
        id: json["id"],
        date: DateTime.parse(json["date"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date.toIso8601String(),
      };

  String get dataFormatada =>
      DateFormat.yMMMMd().format(date); //DateFormat('dd/MM/yyyy').format(date);
}
