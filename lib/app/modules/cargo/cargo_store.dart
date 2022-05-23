import 'package:mobx/mobx.dart';

part 'cargo_store.g.dart';

class CargoStore = CargoStoreBase with _$CargoStore;

abstract class CargoStoreBase with Store {
  @observable
  int value = 0;

  @action
  void increment() {
    value++;
  }
}
