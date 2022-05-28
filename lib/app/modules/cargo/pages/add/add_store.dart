import 'package:mobx/mobx.dart';

part 'add_store.g.dart';

class AddStore = AddStoreBase with _$AddStore;

abstract class AddStoreBase with Store {
  @observable
  int value = 0;

  @action
  void increment() {
    value++;
  }
}
