import 'package:flutter_test/flutter_test.dart';

void main() {
  test('String should be reversed', () {
    String initial = "hello";
    String reversed = initial.split('').reversed.join('');
    expect(reversed, "olleh");
  });

  test('Basic Math Check', () {
      expect(2 + 2, 4);
      expect(10 - 5, 5);
  });
}
