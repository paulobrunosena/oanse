class Cargo {
  int idCargo = -1;
  String nome = "nomeCargo";
  String descricao = "descricaoCargo";

  Cargo({required this.idCargo, required this.nome, required this.descricao});

  Cargo.fromJson(Map<String, dynamic> json) {
    idCargo = json['id_cargo'];
    nome = json['nome'];
    descricao = json['descricao'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id_cargo'] = idCargo;
    data['nome'] = nome;
    data['descricao'] = descricao;
    return data;
  }
}

//List<Cargo> cargoFromJson(String str) => List<Cargo>.from(json.decode(str).map((x) => Cargo.fromJson(x)));
//String cargoToJson(List<Cargo> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));