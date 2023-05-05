import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/model/score_item/score_item_model.dart';

import '../constants.dart';
import 'interfaces/score_item_repository_interface.dart';

class ScoreItemHiveRepository implements IScoreItemRepository {
  ScoreItemHiveRepository() {
    _initDb();
  }
  _initDb() async {
    box = Hive.box<ScoreItemModel>(boxScoreItem);
  }

  late Box<ScoreItemModel> box;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> allScoreItems() async {
    List<ScoreItemModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      List<ScoreItemModel> listScoreItem = [
        ScoreItemModel(
          id: 1,
          name: "Uniforme",
          description: "Vir devidamente uniformizado",
          points: 5000,
        ),
        ScoreItemModel(
          id: 2,
          name: "Manual",
          description: "Trazer manual",
          points: 20000,
        ),
        ScoreItemModel(
          id: 3,
          name: "Conduta + contagem até 5",
          description: "Manter boa conduta durante a reunião do oanse",
          points: 10000,
        ),
        ScoreItemModel(
          id: 4,
          name: "Bíblia",
          description: "Trazer a bíblia",
          points: 5000,
        ),
        ScoreItemModel(
          id: 5,
          name: "Leitura bíblica",
          description: "Realizar a leitura bíblica diária",
          points: 20000,
        ),
        ScoreItemModel(
          id: 6,
          name: "EBD",
          description: "Frequentar a EBD regularmente",
          points: 5000,
        ),
        ScoreItemModel(
          id: 7,
          name: "Visitante",
          description: "Trazer visitante, independente de clube",
          points: 10000,
        ),
        ScoreItemModel(
          id: 8,
          name: "Seção sem ajuda",
          description: "Passar na seção sem ajuda do líder",
          points: 20000,
        ),
        ScoreItemModel(
          id: 9,
          name: "Seção com ajuda",
          description: "Passar na seção com ajuda do líder",
          points: 10000,
        ),
        ScoreItemModel(
          id: 10,
          name: "Atividade extra",
          description: "Realizar as atividades extras do manual",
          points: 15000,
        ),
        ScoreItemModel(
          id: 11,
          name: "Não participou (Esportes)",
          description: "Não participou (Esportes)",
          points: 0,
        ),
        ScoreItemModel(
          id: 12,
          name: "1º Lugar (Esportes)",
          description: "1º Lugar (Esportes)",
          points: 5000,
        ),
        ScoreItemModel(
          id: 13,
          name: "2º Lugar (Esportes)",
          description: "2º Lugar (Esportes)",
          points: 4000,
        ),
        ScoreItemModel(
          id: 14,
          name: "3º Lugar (Esportes)",
          description: "3º Lugar (Esportes)",
          points: 3000,
        ),
        ScoreItemModel(
          id: 15,
          name: "4º Lugar (Esportes)",
          description: "4º Lugar (Esportes)",
          points: 2000,
        ),
      ];
      await box.addAll(listScoreItem);

      return Success(box.values.toList());
    }
  }

  @override
  void dispose() {}
}
