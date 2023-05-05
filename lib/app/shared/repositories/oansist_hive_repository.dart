import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';

import '../constants.dart';
import '../model/oansist/oansist_model.dart';
import 'interfaces/oansist_repository_interface.dart';

class OansistHiveRepository implements IOansistRepository {
  OansistHiveRepository() {
    _initDb();
  }

  _initDb() async {
    box = Hive.box<OansistModel>(boxOansist);
  }

  late Box<OansistModel> box;

  @override
  Future<Result<bool, Exception>> addOansist(OansistModel data) async {
    if (sameName(data.name ?? "")) {
      return Error(Exception("Já existe oansista com o mesmo nome"));
    }

    return Success(await box.add(data) > -1);
  }

  @override
  Future<Result<List<OansistModel>, Exception>> allOansist() async {
    List<OansistModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      await initListOansist();
      return Success(box.values.toList());
    }
  }

  @override
  Future<Result<List<OansistModel>, Exception>> clubOansist(int idClub) async {
    List<OansistModel> list = box.values.toList();
    if (list.isEmpty) {
      await initListOansist();
      list = box.values.toList();
    }

    var result = list
        .where(
          (element) => element.clubId == idClub,
        )
        .toList();

    if (result.isNotEmpty) {
      return Success(result);
    } else {
      return Error(Exception("Não existem oansistas cadastrados para o clube"));
    }
  }

  bool sameName(String name) {
    List<OansistModel> list = box.values.toList();
    if (list.isNotEmpty) {
      var sameName =
          list.where((element) => element.name?.compareTo(name) == 0);
      if (sameName.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  Future<void> initListOansist() async {
    List<OansistModel> listOansist = [
      OansistModel(
        id: 1,
        name: "Maria Clara Shirayanagui",
        birthDate: DateTime.parse("2017-07-15 00:00:00"),
        gender: "F",
        clubId: 1,
      ),
      OansistModel(
        id: 2,
        name: "Asafe Margarido",
        birthDate: DateTime.parse("2017-10-18 00:00:00"),
        gender: "M",
        clubId: 1,
      ),
      OansistModel(
        id: 5,
        name: "Fabrício César de Lima Gomes",
        birthDate: DateTime.parse("2013-01-15 00:00:00"),
        gender: "M",
        clubId: 3,
      ),
      OansistModel(
        id: 7,
        name: "Marcos dos Reis Campêlo",
        birthDate: DateTime.parse("2012-06-13 00:00:00"),
        gender: "M",
        clubId: 3,
      ),
    ];
    await box.addAll(listOansist);
  }

  @override
  void dispose() {}
}
