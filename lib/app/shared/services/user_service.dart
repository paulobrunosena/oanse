import 'package:multiple_result/multiple_result.dart';

import '../model/user/user_model.dart';
import '../repositories/interfaces/user_repository_interface.dart';
import 'interfaces/user_service_interface.dart';

class UserService implements IUserService {
  UserService(this._repository);
  final IUserRepository _repository;

  @override
  Future<Result<List<User>, Exception>> allUsers() async {
    return await _repository.allUsers();
  }

  @override
  void dispose() {}
}
