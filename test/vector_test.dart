import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

void main() {
  group('Vector2', () {
    test('in-place arithmetic mutates and never replaces', () {
      final v = Vector2(1, 2);
      final same = v;
      v
        ..add(Vector2(3, 4))
        ..sub(Vector2(1, 1))
        ..addScaled(Vector2(2, 0), 0.5)
        ..subScaled(Vector2(0, 2), 0.5)
        ..scale(2)
        ..negate();
      expect(identical(v, same), isTrue);
      expect(v, Vector2(-8, -8));
      v.setValues(5, 6);
      expect(v, Vector2(5, 6));
      v.setFrom(Vector2(-1, 7));
      expect(v, Vector2(-1, 7));
      v.setZero();
      expect(v, Vector2.zero());
    });

    test('length, dot, cross and distance', () {
      final a = Vector2(3, 4);
      expect(a.length, 5);
      expect(a.lengthSquared, 25);
      expect(a.dot(Vector2(2, -1)), 2);
      expect(a.cross(Vector2(1, 0)), -4);
      expect(a.distanceTo(Vector2(0, 0)), 5);
      expect(a.distanceToSquared(Vector2(3, 0)), 16);
    });

    test('normalize returns the old length and leaves zero at zero', () {
      final v = Vector2(0, -2);
      expect(v.normalize(), 2);
      expect(v, Vector2(0, -1));
      final zero = Vector2.zero();
      expect(zero.normalize(), 0);
      expect(zero, Vector2.zero());
    });

    test('normalized copies, and gives +X for a zero vector', () {
      final v = Vector2(10, 0);
      expect(v.normalized(), Vector2(1, 0));
      expect(v, Vector2(10, 0));
      expect(Vector2.zero().normalized(), Vector2(1, 0));
    });

    test('perpendicular is (-y, x), in place or as a copy', () {
      final v = Vector2(2, 3);
      expect(v.perpendicular(), Vector2(-3, 2));
      v.setToPerpendicular();
      expect(v, Vector2(-3, 2));
    });

    test('operators return new vectors', () {
      final a = Vector2(1, 2);
      final b = Vector2(3, 5);
      expect(a + b, Vector2(4, 7));
      expect(b - a, Vector2(2, 3));
      expect(a * 3, Vector2(3, 6));
      expect(b / 2, Vector2(1.5, 2.5));
      expect(-a, Vector2(-1, -2));
      expect(a, Vector2(1, 2));
    });

    test('Offset conversions, equality, hash and toString', () {
      final v = Vector2.fromOffset(const Offset(4, -2));
      expect(v.toOffset(), const Offset(4, -2));
      expect(Vector2.copy(v), v);
      expect(Vector2.copy(v).hashCode, v.hashCode);
      expect(v == Vector2(4, -1), isFalse);
      expect(Vector2(1.5, 2.5).toString(), startsWith('Vector2(1.5, 2.5'));
    });
  });

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
      final zero = Vector3.zero();
      expect(zero.normalize(), 0);
      expect(zero, Vector3.zero());
      expect(Vector3.zero().normalized(), Vector3(1, 0, 0));
    });

    test('in-place arithmetic', () {
      final v = Vector3(1, 2, 3)
        ..add(Vector3(1, 1, 1))
        ..sub(Vector3(0, 0, 2))
        ..addScaled(Vector3(2, 0, 0), 0.5)
        ..subScaled(Vector3(0, 2, 0), 0.5)
        ..scale(2)
        ..negate();
      expect(v, Vector3(-6, -4, -4));
    });

    test('dot, cross and distance', () {
      final x = Vector3(1, 0, 0);
      final y = Vector3(0, 1, 0);
      expect(x.dot(y), 0);
      expect(x.cross(y), Vector3(0, 0, 1));
      expect(Vector3(1, 2, 2).distanceTo(Vector3.zero()), 3);
    });

    test('2-D helpers, operators and toString', () {
      final v = Vector3.fromXY(2, 3);
      expect(v, Vector3(2, 3, 0));
      expect(v.toOffset(), const Offset(2, 3));
      expect(Vector3.fromOffset(const Offset(5, 6)), Vector3(5, 6, 0));
      expect(v + Vector3(1, 1, 1), Vector3(3, 4, 1));
      expect(v - Vector3(1, 1, 1), Vector3(1, 2, -1));
      expect(v * 2, Vector3(4, 6, 0));
      expect(v / 2, Vector3(1, 1.5, 0));
      expect(-v, Vector3(-2, -3, 0));
      expect(Vector3(1.5, 2.5, 3.5).toString(), startsWith('Vector3(1.5'));
    });
  });
}
