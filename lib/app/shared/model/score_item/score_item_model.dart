import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'score_item_model.g.dart';

List<ScoreItemModel> scoreItemModelFromJson(List<dynamic> str) =>
    List<ScoreItemModel>.from(str.map((x) => ScoreItemModel.fromJson(x)));

@HiveType(typeId: 3)
class ScoreItemModel {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? description;
  @HiveField(3)
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

  String get pointsFormatter {
    final formatter = NumberFormat('###,###,###');
    return formatter.format(points!);
  }

  bool get isSwitchScore => !(name!.contains('Visitante') ||
      name!.contains('Seção') ||
      name!.contains('Atividade'));

  bool get isSport => name!.contains('Esportes');

  String get nameSports => name!.replaceAll('(Esportes)', '');
}
