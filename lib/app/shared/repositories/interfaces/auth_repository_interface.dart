import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import '../../model/login/login_model.dart';
import '../../model/login/login_request.dart';
import '../../model/logout/logout_response.dart';

abstract class IAuthRepository implements Disposable {
  Future<Result<LoginResponse, Exception>> login(LoginRequest data);
  Future<Result<LogoutResponse, Exception>> logout();
  Future<bool> saveDadosUsuarioLocal(LoginModel data);
}
