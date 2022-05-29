import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

class CustomDio extends DioForNative {
  CustomDio([BaseOptions? options]) : super(options) {
    //interceptors.add(CustomIntercetors());
    /*if (kIsWeb) {
      httpClientAdapter = BrowserHttpClientAdapter();
      if (kDebugMode) {
        print("está rodando flutter web");
      }
    } else {
      httpClientAdapter = DefaultHttpClientAdapter();
      if (kDebugMode) {
        print("está rodando flutter mobile");
      }
    }*/
  }
}
