import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';

import '../constants.dart';
import '../model/exception/exception_response.dart';
import '../model/leadership/leadership_model.dart';
import 'interfaces/leadership_repository_interface.dart';

class LeadershipRepository implements ILeadershipRepository {
  LeadershipRepository(this.client) {
    _initDb();
  }

  _initDb() async {
    box = Hive.box<LeadershipModel>(boxLeadership);
  }

  final Dio client;
  late Box<LeadershipModel> box;

  @override
  Future<Result<List<LeadershipModel>, Exception>> allLeaderships() async {
    try {
      var response = await client.get('leadership/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<LeadershipModel> result =
              leadershipModelFromJson(response.data['response']);
          return Success(result);
        } else {
          return Error(Exception("Não existem leadership cadastrados"));
        }
      } else {
        debugPrint("Erro no all leaderships");
        debugPrint(response.data.toString());
        return Error(Exception("Erro no all leaderships"));
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
  Future<Result<int, Exception>> add(LeadershipModel data) async {
    if (sameUserName(data.name)) {
      return Error(Exception("Já existe líder com o mesmo username"));
    }

    return Success(await box.add(data));
  }

  bool sameUserName(String userName) {
    List<LeadershipModel> list = box.values.toList();
    if (list.isNotEmpty) {
      var sameName =
          list.where((element) => element.userName.compareTo(userName) == 0);
      if (sameName.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<void> put(int key, LeadershipModel data) async {
    await box.putAt(key, data);
  }

  @override
  Future<void> delete(int key) async {
    await box.deleteAt(key);
  }

  @override
  LeadershipModel? get(key) {
    return box.getAt(key);
  }

  @override
  Result<List<LeadershipModel>, Exception> list() {
    List<LeadershipModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      return Error(Exception("Não existem líderes cadastrados"));
    }
  }

  @override
  void dispose() {}
}
