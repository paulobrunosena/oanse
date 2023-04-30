List<LeadershipModel> leadershipModelFromJson(List<dynamic> str) =>
    List<LeadershipModel>.from(str.map((x) => LeadershipModel.fromJson(x)));

class LeadershipModel {
  late int id;
  late String name;
  late String userName;
  late String password;
  int? club;
  int? role;

  LeadershipModel({
    required this.id,
    required this.name,
    required this.userName,
    required this.password,
    this.club,
    this.role,
  });

  LeadershipModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] ?? "";
    userName = json['user_name'] ?? "";
    password = json['password'] ?? "";
    club = json['club'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['password'] = password;
    data['role'] = role;
    data['id'] = id;
    data['user_name'] = userName;
    data['club'] = club;
    return data;
  }
}
