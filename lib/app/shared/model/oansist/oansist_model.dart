import 'package:hive/hive.dart';
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
  String? birthDate;
  @HiveField(3)
  String? gender;
  @HiveField(4)
  int? clubId;

  OansistModel({this.id, this.name, this.birthDate, this.gender, this.clubId});

  OansistModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    birthDate = json['birth_date'];
    gender = json['gender'];
    clubId = json['club'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['birth_date'] = birthDate;
    data['gender'] = gender;
    data['club_id'] = clubId;
    return data;
  }
}
