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
    await box.deleteAt(key);
  }

  @override
  ScoreModel? get(int key) {
    return box.getAt(key);
  }

  @override
  Future<Result<List<ScoreModel>, Exception>> list(
      int idMeeting, int idOansist) async {
    List<ScoreModel> list = box.values.toList();
    return Success(list
        .where((element) =>
            element.meetingId == idMeeting && element.oansistId == idOansist)
        .toList());
  }

  @override
  Future<void> put(int key, ScoreModel data) async {
    await box.putAt(key, data);
  }

  @override
  void dispose() {}
}
