import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/club/club_model.dart';
import '../model/exception/exception_response.dart';
import 'interfaces/club_repository_interface.dart';

class ClubRepository implements IClubRepository {
  ClubRepository(this.client);
  final Dio client;

  @override
  Future<Result<List<ClubModel>, Exception>> allClubs() async {
    try {
      var response = await client.get('club/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<ClubModel> result = clubModelFromJson(response.data['response']);
          return Success(result);
        } else {
          return Error(Exception("Não existem clubes cadastrados"));
        }
      } else {
        debugPrint("Erro no allClubs");
        debugPrint(response.data);
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
  Future<Result<List<ClubModel>, Exception>> allClubsMock() async {
    List<ClubModel> resultMock = [
      ClubModel(
        id: 1,
        name: "Ursinho",
        entryAge: 4,
        leaveAge: 6,
      ),
      ClubModel(
        id: 2,
        name: "Faísca",
        entryAge: 6,
        leaveAge: 9,
      ),
      ClubModel(
        id: 3,
        name: "Flama",
        entryAge: 9,
        leaveAge: 11,
      ),
      ClubModel(
        id: 4,
        name: "Tocha",
        entryAge: 11,
        leaveAge: 13,
      ),
      ClubModel(
        id: 5,
        name: "JV",
        entryAge: 13,
        leaveAge: 15,
      ),
      ClubModel(
        id: 6,
        name: "VQ7",
        entryAge: 15,
        leaveAge: 19,
      ),
    ];
    if (resultMock.isNotEmpty) {
      return Success(resultMock);
    } else {
      return Error(Exception("Não existem clubes cadastrados"));
    }
  }

  @override
  void dispose() {}
}
