import 'package:flutter_modular/flutter_modular.dart';
import 'package:oanse/app/shared/services/interfaces/leadership_service_interface.dart';

import '../../shared/services/interfaces/auth_service_interface.dart';
import 'splash_controller.dart';
import 'splash_page.dart';

class SplashModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => SplashController(
        i<IAuthService>(),
        i<ILeadershipService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const SplashPage()),
  ];
}
