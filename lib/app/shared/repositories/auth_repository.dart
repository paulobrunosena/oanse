import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/exception/exception_response.dart';
import 'package:oanse/app/shared/model/login/login_response.dart';

import '../model/login/login_model.dart';
import '../model/login/login_request.dart';
import '../services/local_storage_service.dart';
import 'interfaces/auth_repository_interface.dart';

class AuthRepository implements IAuthRepository {
  final Dio client;

  AuthRepository(this.client);

  @override
  Future<Result<LoginResponse, Exception>> login(LoginRequest data) async {
    try {
      var response = await client.post('auth/login', data: data.toJson());

      if (response.statusCode == 200) {
        LoginResponse result = LoginResponse.fromJson(response.data);
        client.options.headers["authorization"] = result.authorization;
        return Success(result);
      } else {
        debugPrint("Erro no login");
        debugPrint(response.data);
        return Error(Exception("Erro no login"));
      }
    } on DioError catch (error) {
      if (error.response != null) {
        var responseException =
            ExceptionResponse.fromJson(error.response!.data);
        return Error(Exception(responseException.message));
      } else {
        return Error(Exception(error.message));
      }
    }
  }

  @override
  Future<bool> saveDadosUsuarioLocal(LoginModel data) async {
    bool result = await LocalStorageService.setValue<String>(
        'dados_usuario_local', jsonEncode(data.toJson()));
    return result;
  }

  @override
  void dispose() {}
}
