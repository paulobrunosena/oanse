import 'package:mobx/mobx.dart';
import 'package:oanse/app/shared/model/score/score_model.dart';

part 'score_model_store.g.dart';

class ScoreModelStore = ScoreModelStoreBase with _$ScoreModelStore;

abstract class ScoreModelStoreBase with Store {
  ScoreModelStoreBase(this.scoreModel);
  final ScoreModel scoreModel;

  @observable
  int quantity = 0;

  @action
  setQuantity(int newValue) {
    quantity = newValue;
    scoreModel.quantity = newValue.toString();
  }
}
