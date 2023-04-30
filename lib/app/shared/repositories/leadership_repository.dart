import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/exception/exception_response.dart';
import '../model/leadership/leadership_model.dart';
import 'interfaces/leadership_repository_interface.dart';

class LeadershipRepository implements ILeadershipRepository {
  LeadershipRepository(this.client);
  final Dio client;

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
  void dispose() {}
}
