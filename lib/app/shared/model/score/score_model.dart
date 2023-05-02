class ScoreModel {
  int? id;
  String? quantity;
  int? meetingId;
  int? scoreItemId;
  int? leadershipId;
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
