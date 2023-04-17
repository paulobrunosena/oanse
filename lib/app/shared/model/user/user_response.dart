import 'user_model.dart';

class UserResponse {
  List<User>? listAllUsers;

  UserResponse({this.listAllUsers});

  UserResponse.allUsersfromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      listAllUsers = <User>[];
      json['data'].forEach((user) {
        listAllUsers!.add(User.fromJson(user));
      });
    }
  }

  Map<String, dynamic> allUserstoJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (listAllUsers != null) {
      data['data'] = listAllUsers!.map((user) => user.toJson()).toList();
    }
    return data;
  }
}
