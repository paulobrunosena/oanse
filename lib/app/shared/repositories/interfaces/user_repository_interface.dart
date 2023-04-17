import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/user/user_model.dart';

abstract class IUserRepository implements Disposable {
  Future<Result<List<User>, Exception>> allUsers();
}
