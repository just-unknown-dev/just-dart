import 'dart:math' as math;

import 'package:flutter/painting.dart' show Rect;
import 'package:just_dart/just_dart.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

const _eps = 1e-9;

Matcher _near(double v, [double eps = _eps]) => closeTo(v, eps);

void _expectVec(Vector3 v, double x, double y, double z, [double eps = _eps]) {
  expect(v.x, _near(x, eps), reason: 'x of $v');
  expect(v.y, _near(y, eps), reason: 'y of $v');
  expect(v.z, _near(z, eps), reason: 'z of $v');
}

/// R = Ry · Rx · Rz, built by hand from the documented convention.
vm.Matrix3 _handEuler(double ex, double ey, double ez) {
  final rx = vm.Matrix3.rotationX(ex);
  final ry = vm.Matrix3.rotationY(ey);
  final rz = vm.Matrix3.rotationZ(ez);
  return ry * rx * rz as vm.Matrix3;
}

void main() {
  group('Quaternion', () {
    test('a Z turn carries +X towards +Y (clockwise on a y-down screen)', () {
      final q = Quaternion.identity()..setRotationZ(math.pi / 2);
      final v = Vector3(1, 0, 0);
      q.rotate(v);
      _expectVec(v, 0, 1, 0);
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
        _expectVec(got, want.x, want.y, want.z, 1e-9);
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
        _expectVec(out, ex, ey, ez, 1e-7);
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
      _expectVec(out, 0.2, 0.3, 6.01, 1e-7);
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
      _expectVec(v1, v2.x, v2.y, v2.z);
      // In place, aliasing.
      a.multiply(b);
      expect(a.sameRotation(ab), isTrue);
    });

    test('inverse undoes, slerp ends at its ends and halves an angle', () {
      final q = Quaternion.euler(0.4, -0.2, 1.3);
      final inv = Quaternion.copy(q)..invert();
      final v = Vector3(3, -1, 2);
      q.rotate(v);
      inv.rotate(v);
      _expectVec(v, 3, -1, 2);

      final a = Quaternion.identity();
      final b = Quaternion.identity()..setRotationZ(1.0);
      final s = Quaternion.identity()..setSlerp(a, b, 0);
      expect(s.sameRotation(a), isTrue);
      s.setSlerp(a, b, 1);
      expect(s.sameRotation(b), isTrue);
      s.setSlerp(a, b, 0.5);
      expect(
        s.sameRotation(Quaternion.identity()..setRotationZ(0.5)),
        isTrue,
      );
    });

    test('rotation matrix elements convert back', () {
      final q = Quaternion.euler(0.5, 1.2, -2.0);
      final m = vm.Matrix4.identity()
        ..setFromTrs(Vector3.zero(), q, Vector3(1, 1, 1));
      final s = m.storage;
      final back = Quaternion.identity()
        ..setFromRotationElements(
          s[0], s[4], s[8], s[1], s[5], s[9], s[2], s[6], s[10]);
      expect(back.sameRotation(q), isTrue);
    });
  });

  group('Matrix4', () {
    test('is the very class Flutter exports', () {
      expect(Matrix4, vm.Matrix4);
    });

    test('setFromTrs matches vector_math\'s own composition', () {
      final p = Vector3(4, -3, 7);
      final q = Quaternion.euler(0.3, -0.8, 2.1);
      final s = Vector3(2, 0.5, -1.5);
      final ours = Matrix4.zero()..setFromTrs(p, q, s);
      final theirs = vm.Matrix4.compose(
        vm.Vector3(p.x, p.y, p.z),
        vm.Quaternion(q.x, q.y, q.z, q.w),
        vm.Vector3(s.x, s.y, s.z),
      );
      for (var i = 0; i < 16; i++) {
        expect(ours.storage[i], _near(theirs.storage[i]), reason: 'm[$i]');
      }
    });

    test('the planar path equals the general one', () {
      final general = Matrix4.zero()
        ..setFromTrs(
          Vector3(5, 6, 1),
          Quaternion.identity()..setRotationZ(0.7),
          Vector3(2, 3, 1),
        );
      final planar = Matrix4.zero()..setFromPlanarTrs(5, 6, 1, 0.7, 2, 3, 1);
      for (var i = 0; i < 16; i++) {
        expect(planar.storage[i], _near(general.storage[i]), reason: '$i');
      }
    });

    test('setProduct applies b first and tolerates aliasing', () {
      final a = Matrix4.zero()..setFromPlanarTrs(10, 0, 0, 0, 1, 1, 1);
      final b = Matrix4.zero()..setFromPlanarTrs(0, 0, 0, 0, 2, 2, 2);
      final ab = Matrix4.zero()..setProduct(a, b);
      final v = Vector3(1, 1, 1);
      ab.transformPointInto(v, v);
      _expectVec(v, 12, 2, 2);
      a.setProduct(a, b);
      for (var i = 0; i < 16; i++) {
        expect(a.storage[i], ab.storage[i]);
      }
    });

    test('orthographic y-down maps the view box onto clip space', () {
      final m = Matrix4.zero()
        ..setOrthographicYDown(-100, 100, -50, 50, -10, 10);
      final v = Vector3(-100, -50, -10);
      m.transformPointInto(v, v);
      _expectVec(v, -1, -1, 0);
      v.setValues(100, 50, 10);
      m.transformPointInto(v, v);
      _expectVec(v, 1, 1, 1);
    });

    test('perspective y-down: near → 0, far → 1, y stays down', () {
      final m = Matrix4.zero()
        ..setPerspectiveYDown(math.pi / 2, 2.0, 1, 100);
      final v = Vector3(0, 0, 1);
      m.transformPointInto(v, v);
      expect(v.z, _near(0));
      v.setValues(0, 0, 100);
      m.transformPointInto(v, v);
      expect(v.z, _near(1));
      // 45° down from the axis at the edge of a 90° fov is the bottom edge.
      v.setValues(0, 10, 10);
      m.transformPointInto(v, v);
      expect(v.y, _near(1));
    });
  });

  group('Aabb3, Ray3, Plane, Frustum', () {
    test('a box accumulates, converts and transforms', () {
      final box = Aabb3();
      expect(box.isEmpty, isTrue);
      box
        ..addXYZ(1, 2, 3)
        ..addXYZ(-1, 5, 0);
      _expectVec(box.min, -1, 2, 0);
      _expectVec(box.max, 1, 5, 3);
      expect(box.toRect(), const Rect.fromLTRB(-1, 2, 1, 5));

      final flat = Aabb3.fromRect(const Rect.fromLTWH(0, 0, 10, 10));
      final m = Matrix4.zero()..setFromPlanarTrs(0, 0, 0, math.pi / 4, 1, 1, 1);
      flat.transformInto(m, flat);
      final half = 10 * math.sqrt(2) / 2;
      expect(flat.min.x, _near(-half));
      expect(flat.max.x, _near(half));
      expect(flat.max.y, _near(2 * half));
    });

    test('rays meet planes and boxes', () {
      final ray = Ray3()..setValues(5, 5, -10, 0, 0, 1);
      expect(ray.intersectZ(), 10);
      expect(ray.intersectPlane(Plane()), _near(10));
      final hit = Vector3.zero();
      ray.atInto(10, hit);
      _expectVec(hit, 5, 5, 0);

      final box = Aabb3()
        ..setValues(0, 0, -1, 10, 10, 1);
      expect(ray.intersectAabb(box), _near(9));
      ray.origin.setValues(20, 20, -10);
      expect(ray.intersectAabb(box), isNull);
      // Behind the origin.
      ray.setValues(0, 0, 5, 0, 0, 1);
      expect(ray.intersectZ(), isNull);
    });

    test('a frustum from an ortho camera keeps inside boxes only', () {
      final vp = Matrix4.zero()
        ..setOrthographicYDown(0, 100, 0, 100, -10, 10);
      final f = Frustum()..setFromViewProjection(vp);
      expect(f.intersectsAabb(Aabb3()..setValues(10, 10, 0, 20, 20, 0)),
          isTrue);
      expect(f.intersectsAabb(Aabb3()..setValues(110, 10, 0, 120, 20, 0)),
          isFalse);
      expect(f.intersectsAabb(Aabb3()..setValues(90, 90, 0, 120, 120, 0)),
          isTrue);
      expect(f.containsPoint(Vector3(50, 50, 20)), isFalse);
    });

    test('crossInto matches cross and tolerates aliasing', () {
      final a = Vector3(1, 2, 3);
      final b = Vector3(-2, 0.5, 4);
      final want = a.cross(b);
      a.crossInto(b, a);
      _expectVec(a, want.x, want.y, want.z);
    });
  });
}
