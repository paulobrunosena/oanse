import 'dart:convert';

List<ClubModel> clubModelFromJson(List<dynamic> str) =>
    List<ClubModel>.from(str.map((x) => ClubModel.fromJson(x)));

String clubModelToJson(List<ClubModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ClubModel {
  ClubModel({
    required this.leaveAge,
    required this.id,
    required this.name,
    required this.entryAge,
  });

  int id;
  String name;
  int entryAge;
  int leaveAge;

  factory ClubModel.fromJson(Map<String, dynamic> json) => ClubModel(
        leaveAge: json["leave_age"],
        id: json["id"],
        name: json["name"],
        entryAge: json["entry_age"],
      );

  Map<String, dynamic> toJson() => {
        "leave_age": leaveAge,
        "id": id,
        "name": name,
        "entry_age": entryAge,
      };
}
