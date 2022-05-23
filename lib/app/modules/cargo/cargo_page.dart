import 'package:flutter_modular/flutter_modular.dart';
import 'package:oanse/app/modules/cargo/cargo_store.dart';
import 'package:flutter/material.dart';

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
        children: const <Widget>[],
      ),
    );
  }
}
