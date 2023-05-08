import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../constants.dart';

class Sequence {
  static Future<int> idGenerator() async {
    Box box = Hive.box(boxIdGenerator);
    int id = box.get('sequence', defaultValue: 100);
    debugPrint('id gerado: $id');
    await box.put('sequence', (id + 1));
    return id;
  }

  static int idGeneratorDateTime() {
    final now = DateTime.now();
    debugPrint('id gerado: ${now.microsecondsSinceEpoch}');
    return now.microsecondsSinceEpoch;
  }
}
