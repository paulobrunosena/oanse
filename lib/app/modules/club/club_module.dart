import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/services/club_service.dart';
import 'club_controller.dart';
import 'club_page.dart';

class ClubModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => ClubController(
        i<ClubService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const ClubPage()),
  ];
}
