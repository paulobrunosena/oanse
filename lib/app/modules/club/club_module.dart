import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/constants.dart';
import '../../shared/services/club_service.dart';
import '../../shared/services/meeting_service.dart';
import 'club_controller.dart';
import 'club_page.dart';
import 'pages/details/details_controller.dart';
import 'pages/details/details_page.dart';

class ClubModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => ClubController(
        i<ClubService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => DetailsController(
        i<MeetingService>(),
      ),
    ),
  ];

  @override
  final List<ModularRoute> routes = [
    ChildRoute(Modular.initialRoute, child: (_, args) => const ClubPage()),
    ChildRoute(
      routeClubDetails,
      child: (_, args) => DetailsPage(
        club: args.data,
      ),
    ),
  ];
}
