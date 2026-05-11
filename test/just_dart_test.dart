import 'package:just_dart/just_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Vector3', () {
    test('copy constructor preserves values', () {
      final source = Vector3(3, 4, 5);
      final copy = Vector3.copy(source);
      expect(copy, equals(source));
    });

    test('length and normalize', () {
      final v = Vector3(3, 4, 0);
      expect(v.length, closeTo(5.0, 1e-9));
      final old = v.normalize();
      expect(old, closeTo(5.0, 1e-9));
      expect(v.length, closeTo(1.0, 1e-9));
    });
  });
}
