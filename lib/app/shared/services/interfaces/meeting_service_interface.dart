import 'package:flutter_modular/flutter_modular.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../model/meeting/meeting_model.dart';

abstract class IMeetingService implements Disposable {
  Future<Result<bool, Exception>> addMeeting(MeetingModel data);
  Future<Result<List<MeetingModel>, Exception>> allMeeting();
}
