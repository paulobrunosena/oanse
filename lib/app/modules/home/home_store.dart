import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

part 'home_store.g.dart';

class HomeStore = HomeStoreBase with _$HomeStore;

abstract class HomeStoreBase with Store {
  @observable
  int counter = 0;

  Future<void> increment() async {
    counter = counter + 1;
  }

  Future<void> logout() async {
    Modular.to.pushNamed("/login/");
  }
}
