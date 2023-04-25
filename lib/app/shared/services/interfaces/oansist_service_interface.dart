import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/oansist/oansist_model.dart';

abstract class IOansistService implements Disposable {
  Future<Result<bool, Exception>> addOansist(OansistModel data);
  Future<Result<List<OansistModel>, Exception>> allOansist();
}