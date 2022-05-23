import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CustomError {
  static String getErrorMessageLogin(e) {
    if (e is DioError) {
      if (e.response != null && e.response!.statusCode == 422) {
        return "CPF inválido";
      } else {
        return getErrorMessage(e);
      }
    } else {
      return getErrorMessage(e);
    }
  }

  static String getErrorMessage(e) {
    String error;

    if (e is DioError) {
      switch (e.type) {
        case DioErrorType.connectTimeout:
          error = "Tempo de conexão expirou, tente novamente";
          break;
        case DioErrorType.sendTimeout:
          error = "Tempo de envio expirou, tente novamente";
          break;
        case DioErrorType.receiveTimeout:
          error = "Tempo de recebimento expirou, tente novamente";
          break;
        case DioErrorType.response:
          error = "Ocorreu um erro na resposta do servidor, tente novamente";
          break;
        case DioErrorType.cancel:
          error = "Requisição cancelada, tente novamente";
          break;
        default:
          error = e.message;
      }

      if (kDebugMode) {
        print("objeto de erro");
        print(e);
      }
    } else if (e is String) {
      error = e;
    } else {
      error = "Ocorreu um erro desconhecido, tente novamente";
    }

    return error;
  }
}
