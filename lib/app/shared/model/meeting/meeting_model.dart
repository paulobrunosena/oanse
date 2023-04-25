import 'dart:convert';

List<MeetingModel> meetingModelFromJson(List<dynamic> str) =>
    List<MeetingModel>.from(str.map((x) => MeetingModel.fromJson(x)));

String meetingModelToJson(List<MeetingModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MeetingModel {
  MeetingModel({
    required this.id,
    required this.date,
  });

  int id;
  DateTime date;

  factory MeetingModel.fromJson(Map<String, dynamic> json) => MeetingModel(
        id: json["id"],
        date: DateTime.parse(json["date"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "date": date.toIso8601String(),
      };
}
