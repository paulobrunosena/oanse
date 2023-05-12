import 'package:hive/hive.dart';

part 'leadership_model.g.dart';

List<LeadershipModel> leadershipModelFromJson(List<dynamic> str) =>
    List<LeadershipModel>.from(str.map((x) => LeadershipModel.fromJson(x)));

@HiveType(typeId: 1)
class LeadershipModel {
  @HiveField(0)
  late int? id = DateTime.now().millisecondsSinceEpoch;
  @HiveField(1)
  late String name;
  @HiveField(2)
  late String userName;
  @HiveField(3)
  late String password;
  @HiveField(4)
  int? club;
  @HiveField(5)
  int? role;

  LeadershipModel({
    this.id,
    required this.name,
    required this.userName,
    required this.password,
    this.club,
    this.role,
  }) {
    id = DateTime.now().millisecondsSinceEpoch;
  }

  LeadershipModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'] ?? '';
    userName = json['user_name'] ?? '';
    password = json['password'] ?? '';
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
