import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'expect_vector3.dart';

/// R = Ry · Rx · Rz, built by hand from the documented convention.
vm.Matrix3 _handEuler(double ex, double ey, double ez) {
  final rx = vm.Matrix3.rotationX(ex);
  final ry = vm.Matrix3.rotationY(ey);
  final rz = vm.Matrix3.rotationZ(ez);
  return ry * rx * rz as vm.Matrix3;
}

void main() {
  test('a Z turn carries +X towards +Y (clockwise on a y-down screen)', () {
    final q = Quaternion.identity()..setRotationZ(math.pi / 2);
    final v = Vector3(1, 0, 0);
    q.rotate(v);
    expectVector3(v, 0, 1, 0);
  });

  test('setEuler matches R = Ry · Rx · Rz', () {
    final rnd = math.Random(7);
    for (var i = 0; i < 200; i++) {
      final ex = (rnd.nextDouble() - 0.5) * 6;
      final ey = (rnd.nextDouble() - 0.5) * 6;
      final ez = (rnd.nextDouble() - 0.5) * 6;
      final q = Quaternion.euler(ex, ey, ez);
      final r = _handEuler(ex, ey, ez);
      final v = Vector3(0.3, -1.7, 2.2);
      final got = Vector3.copy(v);
      q.rotate(got);
      final want = r.transformed(vm.Vector3(v.x, v.y, v.z));
      expectVector3(got, want.x, want.y, want.z, 1e-9);
    }
  });

  test('Euler angles round-trip without a hint in the canonical range', () {
    final rnd = math.Random(11);
    final out = Vector3.zero();
    for (var i = 0; i < 500; i++) {
      final ex = (rnd.nextDouble() - 0.5) * (math.pi - 0.01);
      final ey = (rnd.nextDouble() - 0.5) * 2 * (math.pi - 0.01);
      final ez = (rnd.nextDouble() - 0.5) * 2 * (math.pi - 0.01);
      Quaternion.euler(ex, ey, ez).eulerInto(out);
      expectVector3(out, ex, ey, ez, 1e-7);
    }
  });

  test('a hint that reproduces the rotation comes back exactly', () {
    final out = Vector3.zero();
    for (final hint in [
      Vector3(0, 0, 2 * math.pi + 0.3), // 377°
      Vector3(math.pi, 0, math.pi), // the "other" triple of (0, π, 0)
      Vector3(0.1, -7.0, 0.2),
      Vector3(math.pi / 2, 0.4, 0.9), // gimbal lock
    ]) {
      final q = Quaternion.euler(hint.x, hint.y, hint.z);
      q.eulerInto(out, hint: hint);
      expect(out.x, hint.x);
      expect(out.y, hint.y);
      expect(out.z, hint.z);
    }
  });

  test('a hint picks the equivalent triple nearest to it', () {
    // Nudge a rotation set from a hint; the answer stays near the hint.
    final hint = Vector3(0.2, 0.3, 6.0);
    final q = Quaternion.euler(0.2, 0.3, 6.01);
    final out = Vector3.zero();
    q.eulerInto(out, hint: hint);
    expectVector3(out, 0.2, 0.3, 6.01, 1e-7);
  });

  test('gimbal lock keeps the hint\'s z and stays the same rotation', () {
    final q = Quaternion.euler(math.pi / 2, 0.7, 0.2);
    final out = Vector3.zero();
    q.eulerInto(out, hint: Vector3(math.pi / 2, 0, 0.5));
    expect(out.z, 0.5);
    expect(Quaternion.euler(out.x, out.y, out.z).sameRotation(q), isTrue);
  });

  test('product composes (apply b first)', () {
    final a = Quaternion.euler(0.3, 0, 0);
    final b = Quaternion.euler(0, 0, 1.1);
    final ab = Quaternion.identity()..setProduct(a, b);
    final v1 = Vector3(1, 2, 3);
    final v2 = Vector3.copy(v1);
    ab.rotate(v1);
    b.rotate(v2);
    a.rotate(v2);
    expectVector3(v1, v2.x, v2.y, v2.z);
    // In place, aliasing.
    a.multiply(b);
    expect(a.sameRotation(ab), isTrue);
  });

  test('premultiply applies the old value first, then the other', () {
    final a = Quaternion.euler(0.3, 0, 0);
    final b = Quaternion.euler(0, 0, 1.1);
    final q = Quaternion.copy(b)..premultiply(a);
    expect(q.sameRotation(Quaternion.identity()..setProduct(a, b)), isTrue);
    expect(q.sameRotation(Quaternion.identity()..setProduct(b, a)), isFalse);
    final v1 = Vector3(1, 2, 3);
    final v2 = Vector3.copy(v1);
    q.rotate(v1);
    b.rotate(v2);
    a.rotate(v2);
    expectVector3(v1, v2.x, v2.y, v2.z);
  });

  test('conjugate negates the vector part and undoes a unit rotation', () {
    final q = Quaternion.euler(0.4, -0.2, 1.3);
    final c = Quaternion.copy(q)..conjugate();
    expect([c.x, c.y, c.z, c.w], [-q.x, -q.y, -q.z, q.w]);
    final v = Vector3(3, -1, 2);
    q.rotate(v);
    c.rotate(v);
    expectVector3(v, 3, -1, 2);
  });

  test('inverse undoes, slerp ends at its ends and halves an angle', () {
    final q = Quaternion.euler(0.4, -0.2, 1.3);
    final inv = Quaternion.copy(q)..invert();
    final v = Vector3(3, -1, 2);
    q.rotate(v);
    inv.rotate(v);
    expectVector3(v, 3, -1, 2);

    final a = Quaternion.identity();
    final b = Quaternion.identity()..setRotationZ(1.0);
    final s = Quaternion.identity()..setSlerp(a, b, 0);
    expect(s.sameRotation(a), isTrue);
    s.setSlerp(a, b, 1);
    expect(s.sameRotation(b), isTrue);
    s.setSlerp(a, b, 0.5);
    expect(s.sameRotation(Quaternion.identity()..setRotationZ(0.5)), isTrue);
  });

  test('rotation matrix elements convert back, on every branch', () {
    final axes = [
      Vector3(1, 0, 0), // half turns here hit the x, y and z branches
      Vector3(0, 1, 0),
      Vector3(0, 0, 1),
      Vector3(1, 1, 0),
      Vector3(0.2, -1, 0.7),
    ];
    for (final axis in axes) {
      for (final angle in [math.pi, 3.0, 2.5, 0.3]) {
        final q = Quaternion.axisAngle(axis, angle);
        final m = vm.Matrix4.identity()
          ..setFromTrs(Vector3.zero(), q, Vector3(1, 1, 1));
        final s = m.storage;
        final back = Quaternion.identity()
          ..setFromRotationElements(
            s[0],
            s[4],
            s[8],
            s[1],
            s[5],
            s[9],
            s[2],
            s[6],
            s[10],
          );
        expect(back.sameRotation(q), isTrue, reason: '$axis $angle');
      }
    }
  });

  test('Euler angles stay exact near ±90° without a hint', () {
    // 89.98° used to read back as 90°: x snapped to the pole 4.5e-4 rad
    // early.
    final out = Vector3.zero();
    final deg = math.pi / 180;
    Quaternion.euler(89.98 * deg, 0.3, 0.2).eulerInto(out);
    expectVector3(out, 89.98 * deg, 0.3, 0.2, 1e-9);

    final rnd = math.Random(3);
    for (var i = 0; i < 2000; i++) {
      final pole = (i.isEven ? 1 : -1) * math.pi / 2;
      final ex = pole + (rnd.nextDouble() - 0.5) * 2e-3;
      final q = Quaternion.euler(ex, rnd.nextDouble(), rnd.nextDouble());
      q.eulerInto(out);
      final back = Quaternion.euler(out.x, out.y, out.z);
      expect(back.sameRotation(q, 1e-9), isTrue, reason: '$q -> $out');
    }
  });

  test('any hint gives angles that describe the rotation', () {
    final rnd = math.Random(5);
    double r(double k) => (rnd.nextDouble() - 0.5) * k;
    final out = Vector3.zero();
    for (var i = 0; i < 5000; i++) {
      final nearPole = i % 4 == 0;
      final ex = nearPole
          ? (i.isEven ? 1 : -1) * (math.pi / 2 + r(1e-6))
          : r(12);
      final q = Quaternion.euler(ex, r(12), r(12));
      q.eulerInto(out, hint: Vector3(r(20), r(20), r(20)));
      final back = Quaternion.euler(out.x, out.y, out.z);
      expect(back.sameRotation(q, 1e-7), isTrue, reason: '$q -> $out');
    }
  });

  test('slerp takes the short way round', () {
    final a = Quaternion.identity();
    final b = Quaternion.identity()..setRotationZ(1.0);
    final negB = Quaternion(-b.x, -b.y, -b.z, -b.w);
    final s = Quaternion.identity()..setSlerp(a, negB, 0.5);
    expect(s.sameRotation(Quaternion.identity()..setRotationZ(0.5)), isTrue);
    // Nearly parallel: the lerp fallback.
    s.setSlerp(a, Quaternion.identity()..setRotationZ(0.01), 0.5);
    expect(s.sameRotation(Quaternion.identity()..setRotationZ(0.005)), isTrue);
  });

  test('equality is exact, sameRotation is not', () {
    final q = Quaternion.euler(0.1, 0.2, 0.3);
    final neg = Quaternion(-q.x, -q.y, -q.z, -q.w);
    expect(q == Quaternion.copy(q), isTrue);
    expect(q == neg, isFalse);
    expect(q.sameRotation(neg), isTrue);
    expect(Quaternion.identity().isIdentity(), isTrue);
    expect(Quaternion.identity().toString(), startsWith('Quaternion('));
  });
}
