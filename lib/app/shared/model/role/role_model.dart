import 'package:hive/hive.dart';

part 'role_model.g.dart';

@HiveType(typeId: 2)
class RoleModel {
  RoleModel({
    required this.id,
    required this.name,
    required this.description,
  });
  @HiveField(0)
  int id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
}
