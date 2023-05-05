import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:oanse/app/shared/constants.dart';
import 'package:oanse/app/shared/model/leadership/leadership_model.dart';

import 'package:oanse/app/shared/model/oansist/oansist_model.dart';

import '../model/exception/exception_response.dart';
import 'interfaces/oansist_repository_interface.dart';

class OansistRepository implements IOansistRepository {
  OansistRepository(this.client) {
    _initDb();
  }

  _initDb() async {
    box = Hive.box<OansistModel>(boxOansist);
  }

  final Dio client;
  late Box<OansistModel> box;

  @override
  void dispose() {}

  @override
  Future<Result<bool, Exception>> addOansist(OansistModel data) async {
    try {
      var response = await client.post('oansist/', data: data.toJson());

      if (response.statusCode == 201) {
        debugPrint(response.data);
        return const Success(true);
      } else {
        debugPrint("Erro no addOansist");
        debugPrint(response.data);
        return Error(Exception("Erro no addOansist"));
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
  Future<Result<List<OansistModel>, Exception>> allOansist() async {
    try {
      var response = await client.get('oansist/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<OansistModel> result =
              oanseModelFromJson(response.data['response']);
          return Success(result);
        } else {
          return Error(Exception("Não existem datas cadastradas"));
        }
      } else {
        debugPrint("Erro no allUsers");
        debugPrint(response.data.toString());
        return Error(Exception("Erro no allUsers"));
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
  Future<Result<List<OansistModel>, Exception>> clubOansist(
      LeadershipModel data) async {
    try {
      var response = await client.get('oansist/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<OansistModel> result =
              oanseModelFromJson(response.data['response']);

          return Success(
              result.where((element) => element.clubId == data.club).toList());
        } else {
          return Error(Exception("Não existem oansistas cadastrados"));
        }
      } else {
        return Error(Exception("Erro no allUsers"));
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
  Future<Result<int, Exception>> addOansistHive(OansistModel data) async {
    if (sameName(data.name ?? "")) {
      return Error(Exception("Já existe oansista com o mesmo nome"));
    }

    return Success(await box.add(data));
  }

  @override
  Result<List<OansistModel>, Exception> allOansistHive() {
    List<OansistModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      return Error(Exception("Não existem oansistas cadastrados"));
    }
  }

  @override
  Result<List<OansistModel>, Exception> clubOansistHive(int idClub) {
    List<OansistModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(
        list
            .where(
              (element) => element.clubId == idClub,
            )
            .toList(),
      );
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
}
