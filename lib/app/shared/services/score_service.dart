import 'package:multiple_result/multiple_result.dart';

import '../model/score/score_model.dart';
import '../repositories/interfaces/score_repository_interface.dart';
import 'interfaces/score_service_interface.dart';

class ScoreService implements IScoreService {
  ScoreService(this._repository);
  final IScoreRepository _repository;

  @override
  Future<Result<List<ScoreModel>, Exception>> list(
    int idMeeting,
    int idOansist,
  ) async {
    return _repository.list(idMeeting, idOansist);
  }

  @override
  Future<Result<List<ScoreModel>, Exception>> listScoreSports(
    int idMeeting,
    int idOansist,
  ) async {
    return _repository.listScoreSports(idMeeting, idOansist);
  }

  @override
  void dispose() {}

  @override
  Future<Result<int, Exception>> add(ScoreModel data) async {
    return _repository.add(data);
  }

  @override
  Future<void> delete(int key) async {
    return _repository.delete(key);
  }

  @override
  ScoreModel? get(int key) {
    return _repository.get(key);
  }

  @override
  Future<void> put(int key, ScoreModel data) async {
    return _repository.put(key, data);
  }
}
