import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/interfaces/oansist_service_interface.dart';
import 'oansist_controller.dart';
import 'oansist_page.dart';
import 'pages/oansist_add/oansist_add_controller.dart';
import 'pages/oansist_add/oansist_add_page.dart';

class OansistModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => OansistController(
        i<IOansistService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => OansistAddController(
        i<IOansistService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute,
        child: (_, args) => OansistPage(
              leadership: args.data,
            )),
    ChildRoute(
      "/add",
      child: (_, args) => const OansistAddPage(),
      transition: TransitionType.downToUp,
    )
  ];
}
