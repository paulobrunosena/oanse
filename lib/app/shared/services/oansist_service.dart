import 'package:multiple_result/multiple_result.dart';

import '../model/oansist/oansist_model.dart';
import '../repositories/interfaces/oansist_repository_interface.dart';
import 'interfaces/oansist_service_interface.dart';

class OansistService implements IOansistService {
  OansistService(this._repository);
  final IOansistRepository _repository;

  @override
  Future<Result<bool, Exception>> addOansist(OansistModel data) async {
    return await _repository.addOansist(data);
  }

  @override
  Future<Result<List<OansistModel>, Exception>> allOansist() async {
    return await _repository.allOansist();
  }

  @override
  void dispose() {}
}