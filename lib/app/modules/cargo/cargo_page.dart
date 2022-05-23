import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'cargo_store.dart';
import 'model/cargo.dart';

class CargoPage extends StatefulWidget {
  final String title;
  const CargoPage({Key? key, this.title = 'Cargo'}) : super(key: key);
  @override
  CargoPageState createState() => CargoPageState();
}

class CargoPageState extends State<CargoPage> {
  final CargoStore store = Modular.get();

  @override
  void initState() {
    store.list();
    //store.listUsers();
    super.initState();
  }
  //Tela exemplo de usuários pegando os dados de uma api em produção
  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: Observer(
            builder: (_) {
              if (store.loadingList) {
                return Container();
              } else {
                if (store.listUser.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    child: const Text("Nenhum cargo cadastrado"),
                  );
                } else {
                  return ListView.separated(
                    itemCount: store.listUser.length,
                    itemBuilder: (_, index) {
                      User item = store.listUser[index];
                      return ListTile(
                        title: Text(item.name ?? "Nome de usuário"),
                        subtitle: Text("Descrição: ${item.email}"),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      );
                    },
                    separatorBuilder: (_, __) {
                      return const Divider();
                    },
                  );
                }
              }
            },
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Adicionar',
        child: const Icon(Icons.add),
      ),
    );
  }*/

  //Tela de cargos que não está funcionando no flutter web, pois precisa ativar o CORS no header do servidor da API

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(child: Observer(
            builder: (_) {
              if (store.loadingList) {
                return Container();
              } else {
                if (store.listCargo.isEmpty) {
                  return Container(
                    alignment: Alignment.center,
                    child: const Text("Nenhum cargo cadastrado"),
                  );
                } else {
                  return ListView.separated(
                    itemCount: store.listCargo.length,
                    itemBuilder: (_, index) {
                      Cargo item = store.listCargo[index];
                      return ListTile(
                        title: Text(item.nome),
                        subtitle: Text("Descrição: ${item.descricao}"),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded),
                      );
                    },
                    separatorBuilder: (_, __) {
                      return const Divider();
                    },
                  );
                }
              }
            },
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Adicionar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
