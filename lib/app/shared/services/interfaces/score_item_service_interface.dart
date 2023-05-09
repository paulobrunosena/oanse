import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/score_item/score_item_model.dart';

abstract class IScoreItemService implements Disposable {
  Future<Result<List<ScoreItemModel>, Exception>> list();
  ScoreItemModel? get(int key);
  Future<Result<int, Exception>> add(ScoreItemModel data);
  Future<void> put(int key, ScoreItemModel data);
  Future<void> delete(int key);
}
