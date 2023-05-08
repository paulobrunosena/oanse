import 'package:hive/hive.dart';

import '../constants.dart';

class Sequence {
  static Future<int> idGenerator() async {
    Box box = Hive.box(boxIdGenerator);
    int id = box.get('sequence', defaultValue: 1);
    await box.put('sequence', (id + 1));
    return id;
  }
}
