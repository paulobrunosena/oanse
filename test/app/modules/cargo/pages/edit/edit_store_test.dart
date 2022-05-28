import 'package:flutter_test/flutter_test.dart';
import 'package:oanse/app/modules/cargo/pages/edit/edit_store.dart';
 
void main() {
  late EditStore store;

  setUpAll(() {
    store = EditStore();
  });

  test('increment count', () async {
    expect(store.value, equals(0));
    store.increment();
    expect(store.value, equals(1));
  });
}