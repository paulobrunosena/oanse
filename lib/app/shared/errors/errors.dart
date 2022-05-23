abstract class Failure implements Exception {
  String? get message;
}

class DioFailure extends Failure {
  @override
  final String? message;
  final int? statusCode;
  DioFailure({
    this.message,
    this.statusCode,
  });
}
