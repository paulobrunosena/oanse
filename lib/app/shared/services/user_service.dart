import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import '../repositories/interfaces/user_repository_interface.dart';
import 'interfaces/user_service_interface.dart';

class UserService implements IUserService {
  UserService(this._repository);
  final IUserRepository _repository;

  @override
  Future<Result<LoginResponse, Exception>> allUsers() async {
    return await _repository.allUsers();
  }

  @override
  void dispose() {}
}
