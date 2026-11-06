import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

import 'expect_vector3.dart';

void main() {
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

  test('crossInto matches cross and tolerates aliasing', () {
    final a = Vector3(1, 2, 3);
    final b = Vector3(-2, 0.5, 4);
    final want = a.cross(b);
    a.crossInto(b, a);
    expectVector3(a, want.x, want.y, want.z);
  });
}
