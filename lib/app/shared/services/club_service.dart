import 'package:multiple_result/multiple_result.dart';

import '../model/club/club_model.dart';
import '../repositories/interfaces/club_repository_interface.dart';
import 'interfaces/club_service_interface.dart';

class ClubService implements IClubService {
  ClubService(this._repository);
  final IClubRepository _repository;

  @override
  Future<Result<List<ClubModel>, Exception>> allClubs() async {
    return await _repository.allClubs();
  }

  @override
  void dispose() {}
}
