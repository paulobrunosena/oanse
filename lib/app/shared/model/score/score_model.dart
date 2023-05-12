import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'score_model.g.dart';

@HiveType(typeId: 6)
class ScoreModel = ScoreModelBase with _$ScoreModel;

abstract class ScoreModelBase with Store {
  @HiveField(0)
  int? id;
  @HiveField(1)
  @observable
  int quantity = 0;
  @HiveField(2)
  int? meetingId;
  @HiveField(3)
  int? scoreItemId;
  @HiveField(4)
  int? leadershipId;
  @HiveField(5)
  int? oansistId;

  ScoreModelBase(
      {this.id,
      this.quantity = 0,
      this.meetingId,
      this.scoreItemId,
      this.leadershipId,
      this.oansistId,});

  ScoreModelBase.fromJson(Map<String, dynamic> json) {
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

  @action
  void setQuantity(int newValue) {
    quantity = newValue;
  }
}
