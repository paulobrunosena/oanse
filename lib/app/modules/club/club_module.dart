import 'package:flutter_modular/flutter_modular.dart';

import '../../shared/constants.dart';
import '../../shared/services/interfaces/club_service_interface.dart';
import '../../shared/services/interfaces/meeting_service_interface.dart';
import 'club_controller.dart';
import 'club_page.dart';
import 'pages/details/details_controller.dart';
import 'pages/details/details_page.dart';
import 'pages/weekly_score/weekly_score_controller.dart';
import 'pages/weekly_score/weekly_score_page.dart';

class ClubModule extends Module {
  @override
  final List<Bind> binds = [
    Bind.lazySingleton(
      (i) => ClubController(
        i<IClubService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => DetailsController(
        i<IMeetingService>(),
      ),
    ),
    Bind.lazySingleton(
      (i) => WeeklyScoreController(
        i<IMeetingService>(),
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
    ChildRoute(
      routeClubWeeklyScore,
      child: (_, args) => WeeklyScorePage(
        club: args.data,
      ),
    ),
  ];
}
