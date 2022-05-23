import 'package:dartz/dartz.dart';
import 'package:oanse/app/modules/cargo/model/user.dart';

import '../../../shared/errors/errors.dart';
import '../model/cargo.dart';
import '../repository/interfaces/cargo_repository_interface.dart';
import 'interfaces/cargo_service_interface.dart';

class CargoService implements ICargoService {
  final ICargoRepository _repository;

  CargoService(this._repository);

  @override
  Future<Either<Failure, List<Cargo>?>> list() {
    return _repository.list();
  }

  @override
  Future<Either<Failure, int?>> insert(Map<String, dynamic> data) {
    return _repository.insert(data);
  }

  @override
  Future<Either<Failure, int?>> update(Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, int?>> delete(int id) {
    return _repository.delete(id);
  }

  @override
  Future<Either<Failure, List<User>?>> listUser() {
    return _repository.listUser();
  }

  @override
  void dispose() {}
}
