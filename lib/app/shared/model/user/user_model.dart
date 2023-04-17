class User {
  String? email;
  String? username;
  String? password;
  String? publicId;

  User({this.email, this.username, this.password, this.publicId});

  User.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    username = json['username'];
    password = json['password'];
    publicId = json['public_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['username'] = username;
    data['password'] = password;
    data['public_id'] = publicId;
    return data;
  }
}
