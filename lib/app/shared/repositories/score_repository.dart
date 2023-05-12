import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';

import '../constants.dart';
import '../model/score/score_model.dart';
import 'interfaces/score_repository_interface.dart';

class ScoreRepository implements IScoreRepository {
  ScoreRepository() {
    _initDb();
  }
  _initDb() async {
    box = Hive.box<ScoreModel>(boxScore);
  }

  late Box<ScoreModel> box;

  @override
  Future<Result<int, Exception>> add(ScoreModel data) async {
    return Success(await box.add(data));
  }

  @override
  Future<void> delete(int key) async {
    await box.delete(key);
  }

  @override
  ScoreModel? get(int key) {
    return box.get(key);
  }

  @override
  Future<Result<List<ScoreModel>, Exception>> list(
      int idMeeting, int idOansist) async {
    List<ScoreModel> list = box.values.toList();
    var result = list
        .where((element) =>
            element.meetingId == idMeeting &&
            element.oansistId == idOansist &&
            ((element.scoreItemId ?? 0) < 11))
        .toList();
    result.sort((a, b) => a.id!.compareTo(b.id!));
    return Success(result);
  }

  @override
  Future<Result<List<ScoreModel>, Exception>> listScoreSports(
      int idMeeting, int idOansist) async {
    List<ScoreModel> list = box.values.toList();
    var result = list
        .where((element) =>
            element.meetingId == idMeeting &&
            element.oansistId == idOansist &&
            ((element.scoreItemId ?? 0) > 10))
        .toList();
    result.sort((a, b) => a.id!.compareTo(b.id!));

    return Success(result);
  }

  @override
  Future<void> put(int key, ScoreModel data) async {
    await box.put(key, data);
  }

  @override
  void dispose() {}
}
