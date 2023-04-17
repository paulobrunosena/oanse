import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_request.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import '../model/login/login_model.dart';
import '../model/logout/logout_response.dart';
import '../repositories/interfaces/auth_repository_interface.dart';
import 'interfaces/auth_service_interface.dart';

class AuthService implements IAuthService {
  final IAuthRepository _repository;

  AuthService(this._repository);

  @override
  Future<Result<LoginResponse, Exception>> login(LoginRequest data) async {
    return await _repository.login(data);
  }

  @override
  Future<Result<LogoutResponse, Exception>> logout() async {
    return await _repository.logout();
  }

  @override
  Future<bool> saveDadosUsuarioLocal(LoginModel data) async {
    return await _repository.saveDadosUsuarioLocal(data);
  }

  @override
  void dispose() {}
}
