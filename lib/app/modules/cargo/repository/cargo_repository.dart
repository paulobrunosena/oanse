import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../shared/custom_dio/custom_error.dart';
import '../../../shared/errors/errors.dart';
import '../model/cargo.dart';
import 'interfaces/cargo_repository_interface.dart';

class CargoRepository extends Disposable implements ICargoRepository {
  final DioForNative _dio;

  CargoRepository(this._dio);

  @override
  Future<Either<Failure, List<Cargo>?>> list() async {
    try {
      var response = await _dio.get('cargo/');

      var cargos = List<Cargo>.from(
          (response.data as List).map((e) => Cargo.fromJson(e)));
      return Right(cargos);
    } on DioError catch (err) {
      return Left(DioFailure(
          message: CustomError.getErrorMessage(err),
          statusCode: err.response?.statusCode ?? -1));
    }
  }

  @override
  Future<Either<Failure, int?>> insert(Map<String, dynamic> data) async {
    try {
      var response = await _dio.post('cargo/', data: data);

      if (response.statusCode == 201) {
        return const Right(201);
      } else {
        return Left(DioFailure(
            message: "Erro no servidor ", statusCode: response.statusCode));
      }
    } on DioError catch (err) {
      return Left(DioFailure(
          message: CustomError.getErrorMessage(err),
          statusCode: err.response?.statusCode ?? -1));
    }
  }

  @override
  Future<Either<Failure, int?>> update(Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, int?>> delete(int id) {
    throw UnimplementedError();
  }

  //dispose will be called automatically
  @override
  void dispose() {}
}
