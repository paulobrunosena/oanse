import 'package:multiple_result/multiple_result.dart';

import '../model/leadership/leadership_model.dart';
import '../repositories/interfaces/auth_hive_repository_interface.dart';
import 'interfaces/auth_hive_service_interface.dart';

class AuthHiveService implements IAuthHiveService {
  final IAuthHiveRepository _repository;

  AuthHiveService(this._repository);

  @override
  Future<Result<LeadershipModel, Exception>> login(
      String userName, String password) async {
    return await _repository.login(userName, password);
  }

  @override
  Future<void> setDataUserLocal(LeadershipModel data) async {
    return await _repository.setDataUserLocal(data);
  }

  @override
  LeadershipModel? getDataUserLocal() {
    return _repository.getDataUserLocal();
  }

  @override
  Future<void> removeDataUserLocal() async {
    return await _repository.removeDataUserLocal();
  }

  @override
  void dispose() {}
}
