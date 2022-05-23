import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';

import 'interceptors.dart';

class CustomDio extends DioForNative {
  CustomDio([BaseOptions? options]) : super(options) {
    interceptors.add(CustomIntercetors());
  }
}
