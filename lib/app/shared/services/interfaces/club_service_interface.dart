import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/club/club_model.dart';

abstract class IClubService implements Disposable {
  Future<Result<List<ClubModel>, Exception>> allClubs();
  Future<Result<List<ClubModel>, Exception>> allClubsMock();
}
