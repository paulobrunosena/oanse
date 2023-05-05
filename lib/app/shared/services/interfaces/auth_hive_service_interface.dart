import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/leadership/leadership_model.dart';

abstract class IAuthHiveService implements Disposable {
  Future<Result<LeadershipModel, Exception>> login(
      String userName, String password);
  LeadershipModel? getDataUserLocal();
  Future<void> setDataUserLocal(LeadershipModel data);
  Future<void> removeDataUserLocal();
}
