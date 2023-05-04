import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/auth_hive_service_interface.dart';
import 'login_leadership_controller.dart';
import 'login_leadership_page.dart';

class LoginLeadershipModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton((i) => LoginLeadershipController(i<IAuthHiveService>())),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const LoginPage()),
  ];
}
