import 'package:dio/dio.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import 'interfaces/user_repository_interface.dart';

class UserRepository implements IUserRepository {
  UserRepository(this.client);
  final Dio client;

  @override
  Future<Result<LoginResponse, Exception>> allUsers() {
    throw UnimplementedError();
  }

  @override
  void dispose() {}
}
