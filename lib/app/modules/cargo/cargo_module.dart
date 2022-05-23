import 'package:oanse/app/modules/cargo/cargo_Page.dart';
import 'package:oanse/app/modules/cargo/cargo_store.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CargoModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => CargoStore()),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute('/', child: (_, args) => const CargoPage()),
  ];
}
