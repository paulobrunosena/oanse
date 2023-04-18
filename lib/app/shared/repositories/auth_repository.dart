import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/exception/exception_response.dart';
import '../model/login/login_model.dart';
import '../model/login/login_request.dart';
import '../model/login/login_response.dart';
import '../model/logout/logout_response.dart';
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
  Future<Result<LogoutResponse, Exception>> logout() async {
    try {
      client.options.headers["authorization"] =
          " Authorization ${client.options.headers["authorization"]}";
      var response = await client.post('auth/logout');

      if (response.statusCode == 200) {
        LogoutResponse result = LogoutResponse.fromJson(response.data);
        client.options.headers["authorization"] = null;
        return Success(result);
      } else {
        client.options.headers["authorization"] = null;
        return Error(Exception("Erro no logout"));
      }
    } on DioError catch (error) {
      client.options.headers["authorization"] = null;
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
  Future<bool> setDataUserLocal(LoginModel data) async {
    return await LocalStorageService.setValue<String>(
        'dados_usuario_local', jsonEncode(data.toJson()));
  }

  @override
  Future<LoginModel?> getDataUserLocal() async {
    var contains = await LocalStorageService.cointains('dados_usuario_local');
    if (contains) {
      var res = jsonDecode(
          await LocalStorageService.getValue<String>('dados_usuario_local'));
      return LoginModel.fromJson(res);
    } else {
      return null;
    }
  }

  @override
  Future<bool> removeDataUserLocal() async {
    return await LocalStorageService.removeValue('dados_usuario_local');
  }

  @override
  void setToken(String? token) {
    client.options.headers["authorization"] = token;
  }

  @override
  String? getToken() {
    return client.options.headers["authorization"];
  }

  @override
  void dispose() {}
}
