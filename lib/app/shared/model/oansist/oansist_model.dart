List<OansistModel> oanseModelFromJson(List<dynamic> str) =>
    List<OansistModel>.from(str.map((x) => OansistModel.fromJson(x)));

class OansistModel {
  int? id;
  String? name;
  String? birthDate;
  String? gender;
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
