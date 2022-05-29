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
                        title: Text(item.nome ?? "Nome"),
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
        onPressed: () {
          Modular.to.pushNamed('/cargo/add');
        },
        tooltip: 'Adicionar',
        child: const Icon(Icons.add),
      ),
    );
  }
}
