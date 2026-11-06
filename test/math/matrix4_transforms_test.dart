import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

import 'expect_vector3.dart';

void main() {
  test('Matrix4 is the very class Flutter exports', () {
    expect(Matrix4, vm.Matrix4);
  });

  test('the transforms are the Matrix4Transforms extension', () {
    final m = Matrix4.zero();
    Matrix4Transforms(m).setFromPlanarTrs(1, 2, 3, 0, 1, 1, 1);
    final t = Vector3.zero();
    Matrix4Transforms(m).translationInto(t);
    expectVector3(t, 1, 2, 3);
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
      expect(ours.storage[i], near(theirs.storage[i]), reason: 'm[$i]');
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
      expect(planar.storage[i], near(general.storage[i]), reason: '$i');
    }
  });

  test('setProduct applies b first and tolerates aliasing', () {
    final a = Matrix4.zero()..setFromPlanarTrs(10, 0, 0, 0, 1, 1, 1);
    final b = Matrix4.zero()..setFromPlanarTrs(0, 0, 0, 0, 2, 2, 2);
    final ab = Matrix4.zero()..setProduct(a, b);
    final v = Vector3(1, 1, 1);
    ab.transformPointInto(v, v);
    expectVector3(v, 12, 2, 2);
    a.setProduct(a, b);
    for (var i = 0; i < 16; i++) {
      expect(a.storage[i], ab.storage[i]);
    }
  });

  test('orthographic y-down maps the view box onto clip space', () {
    final m = Matrix4.zero()..setOrthographicYDown(-100, 100, -50, 50, -10, 10);
    final v = Vector3(-100, -50, -10);
    m.transformPointInto(v, v);
    expectVector3(v, -1, -1, 0);
    v.setValues(100, 50, 10);
    m.transformPointInto(v, v);
    expectVector3(v, 1, 1, 1);
  });

  test('perspective y-down: near → 0, far → 1, y stays down', () {
    final m = Matrix4.zero()..setPerspectiveYDown(math.pi / 2, 2.0, 1, 100);
    final v = Vector3(0, 0, 1);
    m.transformPointInto(v, v);
    expect(v.z, near(0));
    v.setValues(0, 0, 100);
    m.transformPointInto(v, v);
    expect(v.z, near(1));
    // 45° down from the axis at the edge of a 90° fov is the bottom edge.
    v.setValues(0, 10, 10);
    m.transformPointInto(v, v);
    expect(v.y, near(1));
  });

  test('degenerate projections fail fast in debug builds', () {
    final m = Matrix4.zero();
    expect(
      () => m.setOrthographicYDown(1, 1, 0, 10, 0, 10),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => m.setPerspectiveYDown(math.pi / 2, 1, 0, 100),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => m.setPerspectiveYDown(math.pi, 1, 1, 100),
      throwsA(isA<AssertionError>()),
    );
  });

  test('directions ignore translation, translation reads back', () {
    final m = Matrix4.zero()..setFromPlanarTrs(5, 6, 7, math.pi / 2, 1, 1, 1);
    final d = Vector3(1, 0, 0);
    m.transformDirectionInto(d, d);
    expectVector3(d, 0, 1, 0);
    m.translationInto(d);
    expectVector3(d, 5, 6, 7);
  });
}
