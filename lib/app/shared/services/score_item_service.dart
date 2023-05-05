import 'package:multiple_result/multiple_result.dart';

import '../model/score_item/score_item_model.dart';
import '../repositories/interfaces/score_item_repository_interface.dart';
import 'interfaces/score_item_service_interface.dart';

class ScoreItemService implements IScoreItemService {
  ScoreItemService(this._repository);
  final IScoreItemRepository _repository;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> allScoreItems() async {
    return await _repository.allScoreItems();
  }

  @override
  void dispose() {}
}
