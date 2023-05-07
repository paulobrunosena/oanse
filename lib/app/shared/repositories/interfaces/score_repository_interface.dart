import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/score/score_model.dart';

abstract class IScoreRepository implements Disposable {
  Future<Result<List<ScoreModel>, Exception>> list(
      int idMeeting, int idOansist);
  Future<Result<int, Exception>> add(ScoreModel data);
  Future<void> put(int key, ScoreModel data);
  Future<void> delete(int key);
  ScoreModel? get(int key);
}
