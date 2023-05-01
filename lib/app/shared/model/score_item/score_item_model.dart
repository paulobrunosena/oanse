List<ScoreItemModel> scoreItemModelFromJson(List<dynamic> str) =>
    List<ScoreItemModel>.from(str.map((x) => ScoreItemModel.fromJson(x)));

class ScoreItemModel {
  int? id;
  String? name;
  String? description;
  int? points;

  ScoreItemModel({this.id, this.name, this.description, this.points});

  ScoreItemModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    points = json['points'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['points'] = points;
    return data;
  }
}
