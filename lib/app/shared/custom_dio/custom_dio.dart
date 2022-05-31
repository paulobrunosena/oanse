import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

class CustomDio extends DioForNative {
  CustomDio([BaseOptions? options]) : super(options) {
    //interceptors.add(CustomIntercetors());
    /*if (Platform.isIOS || Platform.isAndroid) {
      httpClientAdapter = DefaultHttpClientAdapter();
      if (kDebugMode) {
        print("está rodando flutter mobile");
      }
    } else {
      httpClientAdapter = BrowserHttpClientAdapter();
      if (kDebugMode) {
        print("está rodando flutter web");
      }
    }*/
  }
}
