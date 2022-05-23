import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class CustomIntercetors extends InterceptorsWrapper {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print("****DADOS DA REQUISIÇÃO****");
      print("BASE_URL: ${options.baseUrl}");
      print("PATH: ${options.path}");
      print("REQUEST[${options.method}]");
      print("CONTENT-TYPE: ${options.contentType}");
    }

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print("****DADOS DO RESPONSE****");
      print("$response");
    }
    return super.onResponse(response, handler);
  }
}
