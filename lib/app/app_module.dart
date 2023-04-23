import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/club/club_module.dart';
import 'modules/home/home_module.dart';
import 'modules/login/login_module.dart';
import 'modules/splash/splash_module.dart';
import 'modules/user/user_module.dart';
import 'shared/constants.dart';
import 'shared/repositories/auth_repository.dart';
import 'shared/repositories/club_repository.dart';
import 'shared/repositories/interfaces/auth_repository_interface.dart';
import 'shared/repositories/interfaces/club_repository_interface.dart';
import 'shared/repositories/interfaces/user_repository_interface.dart';
import 'shared/repositories/user_repository.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/club_service.dart';
import 'shared/services/user_service.dart';

class AppModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => AuthService(i<IAuthRepository>())),
    Bind.lazySingleton((i) => AuthRepository(i<Dio>())),
    Bind.lazySingleton((i) => UserService(i<IUserRepository>())),
    Bind.lazySingleton((i) => UserRepository(i<Dio>())),
    Bind.lazySingleton((i) => ClubService(i<IClubRepository>())),
    Bind.lazySingleton((i) => ClubRepository(i<Dio>())),
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
    ModuleRoute(routeUser, module: UserModule()),
    ModuleRoute(routeClub, module: ClubModule()),
  ];
}
