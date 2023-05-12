import 'package:multiple_result/multiple_result.dart';

import '../model/score_item/score_item_model.dart';
import '../repositories/interfaces/score_item_repository_interface.dart';
import 'interfaces/score_item_service_interface.dart';

class ScoreItemService implements IScoreItemService {
  ScoreItemService(this._repository);
  final IScoreItemRepository _repository;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> list() async {
    return _repository.list();
  }

  @override
  Future<Result<int, Exception>> add(ScoreItemModel data) async {
    return _repository.add(data);
  }

  @override
  Future<void> delete(int key) async {
    return _repository.delete(key);
  }

  @override
  ScoreItemModel? get(int key) {
    return _repository.get(key);
  }

  @override
  Future<void> put(int key, ScoreItemModel data) async {
    return _repository.put(key, data);
  }

  @override
  Future<Result<List<ScoreItemModel>, Exception>> listScoreItemSports() async {
    return _repository.listScoreItemSports();
  }

  @override
  void dispose() {}
}
