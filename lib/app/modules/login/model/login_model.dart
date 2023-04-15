class LoginModel {
  String? email;
  String? senha;
  String? refreshToken;
  String? token;
  String? usuario;

  LoginModel({this.email, this.senha});

  void setEmail(String? value) {
    email = value;
  }

  void setSenha(String? value) {
    senha = value;
  }

  @override
  String toString() => "username: $email | senha: $senha";

  LoginModel.fromJson(Map<String, dynamic> json) {
    email = json['error'];
    senha = json['token'];
  }
}
