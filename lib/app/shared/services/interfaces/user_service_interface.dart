import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

abstract class IUserService implements Disposable {
  Future<Result<LoginResponse, Exception>> allUsers();
}
