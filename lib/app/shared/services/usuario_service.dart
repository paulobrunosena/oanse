import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/login/login_request.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import '../model/login/login_model.dart';
import '../repositories/interfaces/usuario_repository_interface.dart';
import 'interfaces/usuario_service_interface.dart';

class UsuarioService implements IUsuarioService {
  final IUsuarioRepository _repository;

  UsuarioService(this._repository);

  @override
  Future<Result<LoginResponse, Exception>> login(LoginRequest data) async {
    return await _repository.login(data);
  }

  @override
  Future<bool> saveDadosUsuarioLocal(LoginModel data) async {
    return await _repository.saveDadosUsuarioLocal(data);
  }

  @override
  void dispose() {}
}
