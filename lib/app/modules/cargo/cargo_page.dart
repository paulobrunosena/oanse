import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:oanse/app/modules/cargo/cargo_store.dart';
import 'package:flutter/material.dart';
import 'package:oanse/app/modules/cargo/model/cargo.dart';

class CargoPage extends StatefulWidget {
  final String title;
  const CargoPage({Key? key, this.title = 'Cargo'}) : super(key: key);
  @override
  CargoPageState createState() => CargoPageState();
}

class CargoPageState extends State<CargoPage> {
  final CargoStore store = Modular.get();

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
                        subtitle: Text(item.descricao),
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
    );
  }
}
