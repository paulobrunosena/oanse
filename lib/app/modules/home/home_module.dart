import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/auth_service_interface.dart';
import '../../shared/services/interfaces/user_service_interface.dart';
import 'home_controller.dart';
import 'home_page.dart';

class HomeModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => HomeController(
          i<IAuthService>(),
          i<IUserService>(),
        )),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const HomePage()),
  ];
}
