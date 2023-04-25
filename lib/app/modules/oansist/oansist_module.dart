import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/oansist_service_interface.dart';
import 'oansist_controller.dart';
import 'oansist_page.dart';

class OansistModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => OansistController(
        i<IOansistService>(),
      ),
    ),
    /*Bind.lazySingleton(
      (i) => UserAddController(
        i<IUserService>(),
      ),
    ),*/
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const OansistPage()),
    /*ChildRoute(
      "/add",
      child: (_, args) => const UserAddPage(),
      transition: TransitionType.downToUp,
    )*/
  ];
}
