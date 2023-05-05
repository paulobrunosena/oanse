import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/constants.dart';

import '../model/exception/exception_response.dart';
import '../model/score_item/score_item_model.dart';
import 'interfaces/score_item_repository_interface.dart';

class ScoreItemRepository implements IScoreItemRepository {
  ScoreItemRepository(this.client) {
    _initDb();
  }
  _initDb() async {
    box = Hive.box<ScoreItemModel>(boxScoreItem);
  }

  final Dio client;
  late Box<ScoreItemModel> box;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> allScoreItems() async {
    try {
      var response = await client.get('score_item/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<ScoreItemModel> result =
              scoreItemModelFromJson(response.data['response']);
          result.sort((a, b) => a.id!.compareTo(b.id!));
          return Success(result);
        } else {
          return Error(Exception("Não existem score item cadastrados"));
        }
      } else {
        debugPrint("Erro no all score item");
        debugPrint(response.data.toString());
        return Error(Exception("Erro no all score item"));
      }
    } on DioError catch (error) {
      if (error.response != null) {
        var responseException =
            ExceptionResponse.fromJson(error.response!.data);
        return Error(Exception(responseException.message));
      } else {
        return Error(Exception(error.message));
      }
    }
  }

  @override
  Result<List<ScoreItemModel>, Exception> allScoreItemsHive() {
    List<ScoreItemModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      return Error(Exception("Não existem score itens cadastrados"));
    }
  }

  @override
  void dispose() {}
}
