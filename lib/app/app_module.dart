import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/cargo/cargo_module.dart';
import 'modules/home/home_module.dart';
import 'modules/login/login_module.dart';
import 'shared/constants.dart';
import 'shared/custom_dio/custom_dio.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => CustomDio(i<BaseOptions>())),
    Bind.lazySingleton(
      (i) => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: 15000,
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ModuleRoute(Modular.initialRoute, module: LoginModule()),
    ModuleRoute('/login', module: LoginModule()),
    ModuleRoute('/home', module: HomeModule()),
    ModuleRoute('/cargo', module: CargoModule()),
  ];
}
