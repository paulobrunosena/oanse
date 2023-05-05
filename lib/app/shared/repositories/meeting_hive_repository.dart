import 'package:hive/hive.dart';
import 'package:multiple_result/multiple_result.dart';

import '../constants.dart';
import '../model/meeting/meeting_model.dart';
import 'interfaces/meeting_repository_interface.dart';

class MeetingHiveRepository implements IMeetingRepository {
  MeetingHiveRepository() {
    _initDb();
  }
  _initDb() async {
    box = Hive.box<MeetingModel>(boxMeeting);
  }

  late Box<MeetingModel> box;

  @override
  Future<Result<bool, Exception>> addMeeting(MeetingModel data) async {
    return Success(await box.add(data) > -1);
  }

  @override
  Future<Result<List<MeetingModel>, Exception>> allMeeting() async {
    List<MeetingModel> list = box.values.toList();
    if (list.isNotEmpty) {
      return Success(list);
    } else {
      List<MeetingModel> listMeeting = [
        MeetingModel(
          id: 1,
          date: DateTime.parse("2023-04-08 00:00:00"),
        ),
        MeetingModel(
          id: 2,
          date: DateTime.parse("2023-04-15 00:00:00"),
        ),
        MeetingModel(
          id: 3,
          date: DateTime.parse("2023-04-22 00:00:00"),
        ),
        MeetingModel(
          id: 4,
          date: DateTime.parse("2023-04-29 00:00:00"),
        ),
      ];
      await box.addAll(listMeeting);
      return Success(box.values.toList());
    }
  }

  @override
  void dispose() {}
}
