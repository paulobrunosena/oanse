import 'package:hive_flutter/hive_flutter.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/constants.dart';
import 'package:oanse/app/shared/model/leadership/leadership_model.dart';

import 'interfaces/auth_hive_repository_interface.dart';

class AuthHiveRepository implements IAuthHiveRepository {
  late Box<LeadershipModel> box;
  late Box<LeadershipModel> boxUserSession;

  AuthHiveRepository() {
    _initDb();
  }

  _initDb() async {
    box = Hive.box<LeadershipModel>(boxLeadership);
    boxUserSession = Hive.box<LeadershipModel>(boxSession);
  }

  @override
  Future<Result<LeadershipModel, Exception>> login(LeadershipModel data) async {
    if (box.isNotEmpty) {
      var leadershipList = box.values
          .where((element) =>
              element.userName == data.userName &&
              element.password == data.password)
          .toList();
      if (leadershipList.isNotEmpty) {
        return Success(leadershipList.first);
      } else {
        return Error(Exception("Usuário não encontrado"));
      }
    } else {
      return Error(Exception("Nenhum usuário cadastrado"));
    }
  }

  @override
  LeadershipModel? getDataUserLocal() {
    return boxUserSession.get(userSession);
  }

  @override
  Future<void> removeDataUserLocal() async {
    await boxUserSession.delete(userSession);
  }

  @override
  Future<void> setDataUserLocal(LeadershipModel data) async {
    await boxUserSession.put(userSession, data);
  }

  @override
  void dispose() {}
}
