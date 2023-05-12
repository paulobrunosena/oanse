import 'package:flutter/material.dart';

class FormController {
  var key = GlobalKey<FormState>();

  bool validate() {
    final FormState? form = key.currentState;

    if (form != null && form.validate()) {
      form.save();
      return true;
    } else {
      return false;
    }
  }
}
