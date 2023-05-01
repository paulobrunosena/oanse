import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/meeting_service_interface.dart';
import '../../shared/services/interfaces/oansist_service_interface.dart';
import '../../shared/services/interfaces/user_service_interface.dart';
import 'home_leadership_controller.dart';
import 'home_leadership_page.dart';
import 'weekly_score/weekly_score_controller.dart';
import 'weekly_score/weekly_score_page.dart';

class HomeLeadershipModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => HomeLeadershipController(
          i<IAuthService>(),
          i<IUserService>(),
        )),
    Bind.lazySingleton((i) => WeeklyScoreController(
          i<IMeetingService>(),
          i<IOansistService>(),
        )),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute,
        child: (_, args) => HomeLeadershipPage(leadership: args.data)),
    ChildRoute(
      routeLeadershipWeeklyScore,
      child: (_, args) => WeeklyScorePage(
        leadership: args.data,
      ),
    ),
  ];
}
