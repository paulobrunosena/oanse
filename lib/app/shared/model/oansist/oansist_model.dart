import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
part 'oansist_model.g.dart';

List<OansistModel> oanseModelFromJson(List<dynamic> str) =>
    List<OansistModel>.from(str.map((x) => OansistModel.fromJson(x)));

@HiveType(typeId: 5)
class OansistModel {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  DateTime? birthDate;
  @HiveField(3)
  String? gender;
  @HiveField(4)
  int? clubId;

  OansistModel({this.id, this.name, this.birthDate, this.gender, this.clubId});

  OansistModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    birthDate = DateTime.parse(json["birth_date"]);
    gender = json['gender'];
    clubId = json['club'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['birth_date'] = birthDate?.toIso8601String();
    data['gender'] = gender;
    data['club_id'] = clubId;
    return data;
  }

  String get birthDateFormatter =>
      DateFormat.yMMMMd().format(birthDate ?? DateTime.now());
}
