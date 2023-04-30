import 'package:multiple_result/multiple_result.dart';

import '../model/leadership/leadership_model.dart';
import '../repositories/interfaces/leadership_repository_interface.dart';
import 'interfaces/leadership_service_interface.dart';

class LeadershipService implements ILeadershipService {
  LeadershipService(this._repository);
  final ILeadershipRepository _repository;

  @override
  Future<Result<List<LeadershipModel>, Exception>> allLeaderships() async {
    return await _repository.allLeaderships();
  }

  @override
  void dispose() {}
}
