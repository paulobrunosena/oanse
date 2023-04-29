import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/exception/exception_response.dart';
import '../model/meeting/meeting_model.dart';
import 'interfaces/meeting_repository_interface.dart';

class MeetingRepository implements IMeetingRepository {
  MeetingRepository(this.client);
  final Dio client;

  @override
  void dispose() {}

  @override
  Future<Result<bool, Exception>> addMeeting(MeetingModel data) async {
    try {
      var response = await client.post('meeting/', data: data.toJson());

      if (response.statusCode == 201) {
        debugPrint(response.data);
        return const Success(true);
      } else {
        debugPrint("Erro no addMeeting");
        debugPrint(response.data);
        return Error(Exception("Erro no addMeeting"));
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
  Future<Result<List<MeetingModel>, Exception>> allMeeting() async {
    try {
      var response = await client.get('meeting/');

      if (response.statusCode == 200) {
        bool? status = response.data['status'];
        if (status != null && status) {
          List<MeetingModel> result =
              meetingModelFromJson(response.data['response']);
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
}
