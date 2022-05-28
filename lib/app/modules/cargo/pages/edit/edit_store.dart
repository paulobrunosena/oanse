import 'package:mobx/mobx.dart';

part 'edit_store.g.dart';

class EditStore = EditStoreBase with _$EditStore;

abstract class EditStoreBase with Store {
  @observable
  int value = 0;

  @action
  void increment() {
    value++;
  }
}
