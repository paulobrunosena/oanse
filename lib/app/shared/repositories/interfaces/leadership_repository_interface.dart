import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/leadership/leadership_model.dart';

abstract class ILeadershipRepository implements Disposable {
  Future<Result<List<LeadershipModel>, Exception>> allLeaderships();
}
