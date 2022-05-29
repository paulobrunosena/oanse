import 'package:mobx/mobx.dart';
import 'package:oanse/app/shared/utils/form_controller.dart';

import '../../model/cargo.dart';

part 'add_store.g.dart';

class AddStore = AddStoreBase with _$AddStore;

abstract class AddStoreBase with Store {
  final Cargo cargo = Cargo();
  final FormController formController = FormController();

  Future<void> save() async {
    if (formController.validate()) {
      print("passou na validação");
      print("Nome: ${cargo.nome}");
      print("Descrição: ${cargo.descricao}");
    } else {
      print("Não passou na validação");
    }
  }

  String? validateNome(String? value) {
    if (value == null || value.isEmpty) return "Nome obrigatório";
    return null;
  }

  String? validateDescricao(String? value) {
    if (value == null || value.isEmpty) return "Descrição obrigatória";
    return null;
  }
}
