import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/oansist/oansist_model.dart';

abstract class IOansistRepository implements Disposable {
  Future<Result<bool, Exception>> addOansist(OansistModel data);
  Future<Result<List<OansistModel>, Exception>> allOansist();
  Future<Result<List<OansistModel>, Exception>> clubOansist(int idClub);
}
