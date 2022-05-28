import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

class CustomDio extends DioForNative {
  CustomDio([BaseOptions? options]) : super(options) {
    //interceptors.add(CustomIntercetors());
    //TODO ativar quando for gerar o flutter web
    /*if (kIsWeb) {
      httpClientAdapter = BrowserHttpClientAdapter();
    }*/
  }
}
