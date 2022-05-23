import 'package:flutter_modular/flutter_modular.dart';

import 'modules/cargo/cargo_module.dart';
import 'modules/home/home_module.dart';
import 'modules/login/login_module.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRoute> routes = [
    ModuleRoute(Modular.initialRoute, module: LoginModule()),
    ModuleRoute('/login', module: LoginModule()),
    ModuleRoute('/home', module: HomeModule()),
    ModuleRoute('/cargo', module: CargoModule()),
  ];
}
