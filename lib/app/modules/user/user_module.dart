import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/user_service_interface.dart';
import 'pages/user_add/user_add_controller.dart';
import 'pages/user_add/user_add_page.dart';
import 'user_controller.dart';
import 'user_page.dart';

class UserModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => UserController(
        i<IUserService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => UserAddController(
        i<IUserService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const UserPage()),
    ChildRoute(
      '/add',
      child: (_, args) => const UserAddPage(),
      transition: TransitionType.downToUp,
    )
  ];
}
