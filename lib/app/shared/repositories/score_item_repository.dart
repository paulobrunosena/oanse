import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/exception/exception_response.dart';
import '../model/score_item/score_item_model.dart';
import 'interfaces/score_item_repository_interface.dart';

class ScoreItemRepository implements IScoreItemRepository {
  ScoreItemRepository(this.client);

  final Dio client;

  @override
  Future<Result<List<ScoreItemModel>, Exception>> list() async {
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
  ScoreItemModel? get(int key) {
    return null;
  }

  @override
  void dispose() {}

  @override
  Future<Result<int, Exception>> add(ScoreItemModel data) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(int key) {
    throw UnimplementedError();
  }

  @override
  Future<void> put(int key, ScoreItemModel data) {
    throw UnimplementedError();
  }
}
