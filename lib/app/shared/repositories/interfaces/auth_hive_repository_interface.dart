import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/leadership/leadership_model.dart';

abstract class IAuthHiveRepository implements Disposable {
  Future<Result<LeadershipModel, Exception>> login(LeadershipModel data);
  LeadershipModel? getDataUserLocal();
  Future<void> setDataUserLocal(LeadershipModel data);
  Future<void> removeDataUserLocal();
}
