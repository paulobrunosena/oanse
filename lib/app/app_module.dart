import 'package:dio/dio.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/club/club_module.dart';
import 'modules/home/home_module.dart';
import 'modules/home_leadership/home_leadership_module.dart';
import 'modules/login/login_module.dart';
import 'modules/oansist/oansist_module.dart';
import 'modules/splash/splash_module.dart';
import 'modules/user/user_module.dart';
import 'shared/constants.dart';
import 'shared/repositories/auth_repository.dart';
import 'shared/repositories/club_repository.dart';
import 'shared/repositories/interfaces/auth_repository_interface.dart';
import 'shared/repositories/interfaces/club_repository_interface.dart';
import 'shared/repositories/interfaces/leadership_repository_interface.dart';
import 'shared/repositories/interfaces/meeting_repository_interface.dart';
import 'shared/repositories/interfaces/oansist_repository_interface.dart';
import 'shared/repositories/interfaces/score_item_repository_interface.dart';
import 'shared/repositories/interfaces/user_repository_interface.dart';
import 'shared/repositories/leadership_repository.dart';
import 'shared/repositories/meeting_repository.dart';
import 'shared/repositories/oansist_repository.dart';
import 'shared/repositories/score_item_repository.dart';
import 'shared/repositories/user_repository.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/club_service.dart';
import 'shared/services/leadership_service.dart';
import 'shared/services/meeting_service.dart';
import 'shared/services/oansist_service.dart';
import 'shared/services/score_item_service.dart';
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
    Bind.lazySingleton((i) => OansistService(i<IOansistRepository>())),
    Bind.lazySingleton((i) => OansistRepository(i<Dio>())),
    Bind.lazySingleton((i) => MeetingService(i<IMeetingRepository>())),
    Bind.lazySingleton((i) => MeetingRepository(i<Dio>())),
    Bind.lazySingleton((i) => LeadershipService(i<ILeadershipRepository>())),
    Bind.lazySingleton((i) => LeadershipRepository(i<Dio>())),
    Bind.lazySingleton((i) => ScoreItemService(i<IScoreItemRepository>())),
    Bind.lazySingleton((i) => ScoreItemRepository(i<Dio>())),
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
    ModuleRoute(routeHomeLeadership, module: HomeLeadershipModule()),
    ModuleRoute(routeUser, module: UserModule()),
    ModuleRoute(routeClub, module: ClubModule()),
    ModuleRoute(routeOansist, module: OansistModule()),
  ];
}
