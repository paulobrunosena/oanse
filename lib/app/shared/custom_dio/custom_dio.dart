import 'package:dio/adapter_browser.dart';
import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:flutter/foundation.dart';

import 'interceptors.dart';

class CustomDio extends DioForNative {
  CustomDio([BaseOptions? options]) : super(options) {
    interceptors.add(CustomIntercetors());
    if (kIsWeb) {
      httpClientAdapter = BrowserHttpClientAdapter();
    }
  }
}
