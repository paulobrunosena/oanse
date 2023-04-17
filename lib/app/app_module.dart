import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/home/home_module.dart';
import 'modules/login/login_module.dart';
import 'modules/splash/splash_module.dart';
import 'shared/constants.dart';
import 'shared/repositories/auth_repository.dart';
import 'shared/repositories/interfaces/auth_repository_interface.dart';
import 'shared/repositories/interfaces/usuario_repository_interface.dart';
import 'shared/repositories/usuario_repository.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/usuario_service.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => AuthService(i<IAuthRepository>())),
    Bind.lazySingleton((i) => AuthRepository(i<Dio>())),
    Bind.lazySingleton((i) => UsuarioService(i<IUsuarioRepository>())),
    Bind.lazySingleton((i) => UsuarioRepository(i<Dio>())),
    Bind((i) => Dio(i<BaseOptions>())),
    Bind(
      (i) => BaseOptions(
        baseUrl: baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveDataWhenStatusError: true,
      ),
    )
  ];

  @override
  final List<ModularRoute> routes = [
    ModuleRoute(Modular.initialRoute, module: SplashModule()),
    ModuleRoute(routeLogin, module: LoginModule()),
    ModuleRoute(routeHome, module: HomeModule()),
  ];
}
