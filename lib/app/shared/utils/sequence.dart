import 'dart:developer';

import 'package:hive/hive.dart';

import '../constants.dart';

class Sequence {
  static Future<int> idGenerator() async {
    final Box box = Hive.box(boxIdGenerator);
    final int id = box.get('sequence', defaultValue: 100);
    log('id gerado: $id');
    await box.put('sequence', (id + 1));
    return id;
  }

  static int idGeneratorDateTime() {
    final now = DateTime.now();
    log('id gerado: ${now.microsecondsSinceEpoch}');
    return now.microsecondsSinceEpoch;
  }
}
