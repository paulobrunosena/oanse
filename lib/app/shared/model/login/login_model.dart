class LoginModel {
  String? email;
  String? senha;
  String? token;

  LoginModel({this.email, this.senha});

  void setEmail(String? value) {
    email = value;
  }

  void setSenha(String? value) {
    senha = value;
  }

  void setToken(String? value) {
    token = value;
  }

  @override
  String toString() => "username: $email | senha: $senha";

  LoginModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    senha = json['senha'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['senha'] = senha;
    data['token'] = token;
    return data;
  }
}
