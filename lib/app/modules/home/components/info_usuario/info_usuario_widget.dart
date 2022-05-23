import 'package:flutter/material.dart';

import '../../../../shared/models/user_model.dart';

class InfoUsuarioWidget extends StatelessWidget {
  final UserModel? usuario;

  const InfoUsuarioWidget({Key? key, this.usuario}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          "Olá, ${usuario!.nome}",
          style: const TextStyle(color: Colors.blue, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        Text("CPF: ${usuario!.cpf}",
            style: const TextStyle(color: Colors.grey, fontSize: 15))
      ],
    );
  }
}
