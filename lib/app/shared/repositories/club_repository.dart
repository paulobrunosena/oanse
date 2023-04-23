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
        List<ClubModel> result = clubModelFromJson(response.data);
        return Success(result);
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
  void dispose() {}
}
