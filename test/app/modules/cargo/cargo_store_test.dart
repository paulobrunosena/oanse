import 'package:flutter_test/flutter_test.dart';
import 'package:oanse/app/modules/cargo/cargo_store.dart';
 
void main() {
  late CargoStore store;

  setUpAll(() {
    store = CargoStore();
  });

  test('increment count', () async {
    expect(store.value, equals(0));
    store.increment();
    expect(store.value, equals(1));
  });
}