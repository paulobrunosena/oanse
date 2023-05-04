import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app/app_module.dart';
import 'app/app_widget.dart';
import 'app/shared/constants.dart';
import 'app/shared/model/club/club_model.dart';
import 'app/shared/model/leadership/leadership_model.dart';
import 'app/shared/model/role/role_model.dart';
import 'app/shared/model/score_item/score_item_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(LeadershipModelAdapter());
  Hive.registerAdapter(ClubModelAdapter());
  Hive.registerAdapter(RoleModelAdapter());
  Hive.registerAdapter(ScoreItemModelAdapter());

  await Hive.openBox<LeadershipModel>(boxLeadership);
  await Hive.openBox<ClubModel>(boxClub);
  await Hive.openBox<RoleModel>(boxRole);
  await Hive.openBox<ScoreItemModel>(boxScoreItem);
  //await Hive.openBox(boxMeeting);
  //await Hive.openBox(boxScore);

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(ModularApp(module: AppModule(), child: const AppWidget()));
    configLoading();
  });
}

void configLoading() {
  Intl.defaultLocale = 'pt_BR';
  initializeDateFormatting();
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.dark
    ..maskType = EasyLoadingMaskType.black
    ..userInteractions = false
    ..dismissOnTap = false;
}
