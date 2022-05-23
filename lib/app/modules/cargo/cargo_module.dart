import 'package:dio/native_imp.dart';
import 'package:oanse/app/modules/cargo/cargo_Page.dart';
import 'package:oanse/app/modules/cargo/cargo_store.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'repository/cargo_repository.dart';
import 'repository/interfaces/cargo_repository_interface.dart';
import 'services/cargo_service.dart';

class CargoModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => CargoStore()),
    Bind.lazySingleton((i) => CargoService(i<ICargoRepository>())),
    Bind.lazySingleton((i) => CargoRepository(i<DioForNative>())),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute('/', child: (_, args) => const CargoPage()),
  ];
}
