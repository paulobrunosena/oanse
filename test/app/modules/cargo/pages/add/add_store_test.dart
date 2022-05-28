import 'package:flutter_test/flutter_test.dart';
import 'package:oanse/app/modules/cargo/pages/add/add_store.dart';
 
void main() {
  late AddStore store;

  setUpAll(() {
    store = AddStore();
  });

  test('increment count', () async {
    expect(store.value, equals(0));
    store.increment();
    expect(store.value, equals(1));
  });
}