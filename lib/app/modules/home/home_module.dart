import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/meeting_service_interface.dart';
import '../../shared/services/interfaces/oansist_service_interface.dart';
import '../../shared/services/interfaces/score_item_service_interface.dart';
import '../../shared/services/interfaces/score_service_interface.dart';
import '../../shared/services/interfaces/user_service_interface.dart';
import 'home_controller.dart';
import 'home_page.dart';
import 'weekly_score/weekly_score_controller.dart';
import 'weekly_score/weekly_score_page.dart';

class HomeModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => HomeController(
        i<IAuthService>(),
        i<IAuthHiveService>(),
        i<IUserService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => WeeklyScoreController(
        i<IMeetingService>(),
        i<IOansistService>(),
        i<IScoreItemService>(),
        i<IScoreService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(
      Modular.initialRoute,
      child: (_, args) => HomePage(leadership: args.data),
    ),
    ChildRoute(
      routeWeeklyScore,
      child: (_, args) => WeeklyScorePage(
        leadership: args.data,
      ),
    ),
  ];
}
