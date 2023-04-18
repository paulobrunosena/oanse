import 'package:multiple_result/multiple_result.dart';

import '../model/login/login_model.dart';
import '../model/login/login_request.dart';
import '../model/login/login_response.dart';
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
  Future<bool> setDataUserLocal(LoginModel data) async {
    return await _repository.setDataUserLocal(data);
  }

  @override
  Future<LoginModel?> getDataUserLocal() async {
    return await _repository.getDataUserLocal();
  }

  @override
  Future<bool> removeDataUserLocal() async {
    return await _repository.removeDataUserLocal();
  }

  @override
  void setToken(String? token) {
    _repository.setToken(token);
  }

  @override
  String? getToken() {
    return _repository.getToken();
  }

  @override
  void dispose() {}
}
