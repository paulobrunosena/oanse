import 'package:dartz/dartz.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../../shared/errors/errors.dart';
import '../../model/cargo.dart';

abstract class ICargoRepository implements Disposable {
  Future<Either<Failure, List<Cargo>?>> list();
  Future<Either<Failure, int?>> insert(Map<String, dynamic> data);
  Future<Either<Failure, int?>> update(int id, Map<String, dynamic> data);
  Future<Either<Failure, int?>> delete(int id);
}
