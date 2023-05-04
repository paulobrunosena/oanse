import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/leadership_service_interface.dart';
import 'leadership_controller.dart';
import 'leadership_page.dart';
import 'pages/user_add/leadership_add_controller.dart';
import 'pages/user_add/leadership_add_page.dart';

class LeadershipModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => LeadershipController(
        i<ILeadershipService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => LeadershipAddController(
        i<ILeadershipService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute,
        child: (_, args) => const LeadershipPage()),
    ChildRoute(
      "/add",
      child: (_, args) => const LeadershipAddPage(),
      transition: TransitionType.downToUp,
    )
  ];
}
