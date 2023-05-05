import 'package:multiple_result/multiple_result.dart';

import '../model/meeting/meeting_model.dart';
import '../repositories/interfaces/meeting_repository_interface.dart';
import 'interfaces/meeting_service_interface.dart';

class MeetingService implements IMeetingService {
  MeetingService(this._repository);
  final IMeetingRepository _repository;

  @override
  Future<Result<bool, Exception>> addMeeting(MeetingModel data) async {
    return await _repository.addMeeting(data);
  }

  @override
  Future<Result<List<MeetingModel>, Exception>> allMeeting() async {
    return await _repository.allMeeting();
  }

  @override
  void dispose() {}
}
