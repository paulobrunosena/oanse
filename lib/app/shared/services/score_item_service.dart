import 'package:multiple_result/multiple_result.dart';

import '../model/score_item/score_item_model.dart';
import '../repositories/interfaces/score_item_repository_interface.dart';
import 'interfaces/score_item_service_interface.dart';

class ScoreItemService implements IScoreItemService {
  ScoreItemService(this._repository);
  final IScoreItemRepository _repository;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> list() async {
    return await _repository.list();
  }

  @override
  Future<Result<int, Exception>> add(ScoreItemModel data) async {
    return await _repository.add(data);
  }

  @override
  Future<void> delete(int key) async {
    return await _repository.delete(key);
  }

  @override
  ScoreItemModel? get(int key) {
    return _repository.get(key);
  }

  @override
  Future<void> put(int key, ScoreItemModel data) async {
    return await _repository.put(key, data);
  }

  @override
  void dispose() {}
}
