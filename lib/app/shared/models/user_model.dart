import 'dart:convert';

class UserModel {
  UserModel({
    this.nome,
    this.cpf,
  });

  final String? nome;
  final String? cpf;

  UserModel copyWith({
    String? nome,
    String? cpf,
  }) =>
      UserModel(
        nome: nome ?? this.nome,
        cpf: cpf ?? this.cpf,
      );

  factory UserModel.fromRawJson(String str) => UserModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        nome: json["nome"],
        cpf: json["cpf"],
      );

  Map<String, dynamic> toJson() => {
        "nome": nome,
        "cpf": cpf,
      };
}
