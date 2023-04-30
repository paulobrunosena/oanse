import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/exception/exception_response.dart';
import '../model/user/user_model.dart';
import '../model/user/user_response.dart';
import 'interfaces/user_repository_interface.dart';

class UserRepository implements IUserRepository {
  UserRepository(this.client);
  final Dio client;
  @override
  Future<Result<List<User>, Exception>> allUsers() async {
    try {
      var response = await client.get('user/');

      if (response.statusCode == 200) {
        UserResponse result = UserResponse.allUsersfromJson(response.data);
        return Success(result.listAllUsers ?? []);
      } else {
        debugPrint("Erro no allUsers");
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
