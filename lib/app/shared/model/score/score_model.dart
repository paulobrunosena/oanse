import 'package:hive/hive.dart';

part 'score_model.g.dart';

@HiveType(typeId: 6)
class ScoreModel {
  @HiveField(0)
  int? id;
  @HiveField(1)
  String? quantity;
  @HiveField(2)
  int? meetingId;
  @HiveField(3)
  int? scoreItemId;
  @HiveField(4)
  int? leadershipId;
  @HiveField(5)
  int? oansistId;

  ScoreModel(
      {this.id,
      this.quantity,
      this.meetingId,
      this.scoreItemId,
      this.leadershipId,
      this.oansistId});

  ScoreModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    quantity = json['quantity'];
    meetingId = json['meeting_id'];
    scoreItemId = json['score_item_id'];
    leadershipId = json['leadership_id'];
    oansistId = json['oansist_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['quantity'] = quantity;
    data['meeting_id'] = meetingId;
    data['score_item_id'] = scoreItemId;
    data['leadership_id'] = leadershipId;
    data['oansist_id'] = oansistId;
    return data;
  }

  int get quantityForInt => int.parse(quantity ?? "0");

  void setQuantity(int newValue) {
    quantity = newValue.toString();
  }
}
