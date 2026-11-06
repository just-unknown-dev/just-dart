import 'dart:math' as math;

import 'package:flutter/painting.dart' show Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

import 'expect_vector3.dart';

void main() {
  test('a box accumulates, converts and transforms', () {
    final box = Aabb3();
    expect(box.isEmpty, isTrue);
    box
      ..addXYZ(1, 2, 3)
      ..addXYZ(-1, 5, 0);
    expectVector3(box.min, -1, 2, 0);
    expectVector3(box.max, 1, 5, 3);
    expect(box.toRect(), const Rect.fromLTRB(-1, 2, 1, 5));

    final flat = Aabb3.fromRect(const Rect.fromLTWH(0, 0, 10, 10));
    final m = Matrix4.zero()..setFromPlanarTrs(0, 0, 0, math.pi / 4, 1, 1, 1);
    flat.transformInto(m, flat);
    final half = 10 * math.sqrt(2) / 2;
    expect(flat.min.x, near(-half));
    expect(flat.max.x, near(half));
    expect(flat.max.y, near(2 * half));
  });

  test('minMax copies its corners', () {
    final lo = Vector3(-1, -2, -3);
    final hi = Vector3(4, 5, 6);
    final box = Aabb3.minMax(lo, hi);
    lo.setValues(0, 0, 0);
    hi.setValues(0, 0, 0);
    expectVector3(box.min, -1, -2, -3);
    expectVector3(box.max, 4, 5, 6);
    expect(box.isEmpty, isFalse);
  });

  test('setFromRect spans the rect in x/y and the given depth', () {
    final box = Aabb3()
      ..setFromRect(const Rect.fromLTWH(10, 20, 30, 40), minZ: -2, maxZ: 3);
    expectVector3(box.min, 10, 20, -2);
    expectVector3(box.max, 40, 60, 3);
    box.setFromRect(const Rect.fromLTWH(1, 1, 1, 1));
    expectVector3(box.min, 1, 1, 0);
    expectVector3(box.max, 2, 2, 0);
  });

  test('addBox grows to contain the other box, and an empty box adds '
      'nothing', () {
    final box = Aabb3()..setValues(0, 0, 0, 1, 1, 1);
    box.addBox(Aabb3()..setValues(-2, 0.5, 0.5, 0.5, 3, 0.5));
    expectVector3(box.min, -2, 0, 0);
    expectVector3(box.max, 1, 3, 1);

    // An empty box's corners are ±∞: adding them would make the box
    // infinite.
    box.addBox(Aabb3());
    expectVector3(box.min, -2, 0, 0);
    expectVector3(box.max, 1, 3, 1);

    final grown = Aabb3()..addBox(Aabb3()..setValues(1, 2, 3, 4, 5, 6));
    expectVector3(grown.min, 1, 2, 3);
    expectVector3(grown.max, 4, 5, 6);
  });

  test('intersects counts touching and needs an overlap on every axis', () {
    final box = Aabb3()..setValues(0, 0, 0, 10, 10, 10);
    expect(box.intersects(Aabb3()..setValues(5, 5, 5, 15, 15, 15)), isTrue);
    expect(box.intersects(Aabb3()..setValues(10, 0, 0, 20, 10, 10)), isTrue);
    expect(box.intersects(Aabb3()..setValues(2, 2, 2, 3, 3, 3)), isTrue);
    expect(box.intersects(Aabb3()..setValues(11, 0, 0, 20, 10, 10)), isFalse);
    expect(box.intersects(Aabb3()..setValues(0, -5, 0, 10, -1, 10)), isFalse);
    expect(box.intersects(Aabb3()..setValues(0, 0, 11, 10, 10, 20)), isFalse);
    expect(box.intersects(Aabb3()), isFalse);
  });

  test('containsPoint counts the surface', () {
    final box = Aabb3()..setValues(0, 0, 0, 1, 1, 1);
    expect(box.containsPoint(Vector3(0.5, 0.5, 0.5)), isTrue);
    expect(box.containsPoint(Vector3(1, 1, 1)), isTrue);
    expect(box.containsPoint(Vector3(1, 1, 1.01)), isFalse);
  });

  test('centerInto and sizeInto write the centre and the extent', () {
    final box = Aabb3()..setValues(-2, 0, 4, 6, 10, 5);
    final out = Vector3.zero();
    box.centerInto(out);
    expectVector3(out, 2, 5, 4.5);
    box.sizeInto(out);
    expectVector3(out, 8, 10, 1);
  });

  test('copy, setFrom and setEmpty', () {
    final box = Aabb3()..setValues(1, 2, 3, 4, 5, 6);
    final copy = Aabb3.copy(box);
    box.setEmpty();
    expect(box.isEmpty, isTrue);
    expectVector3(copy.min, 1, 2, 3);
    box.setFrom(copy);
    expectVector3(box.max, 4, 5, 6);
    expect(box.toString(), startsWith('Aabb3('));
  });

  test('transformInto matches the eight transformed corners', () {
    final rnd = math.Random(9);
    double r() => (rnd.nextDouble() - 0.5) * 10;
    final box = Aabb3();
    final want = Aabb3();
    final p = Vector3.zero();
    for (var i = 0; i < 200; i++) {
      final m = Matrix4.zero()
        ..setFromTrs(
          Vector3(r(), r(), r()),
          Quaternion.euler(r(), r(), r()),
          Vector3(r(), r(), r()),
        );
      box.setValues(-1, -2, -3, 2, 1, 4);
      want.setEmpty();
      for (final x in [box.min.x, box.max.x]) {
        for (final y in [box.min.y, box.max.y]) {
          for (final z in [box.min.z, box.max.z]) {
            p.setValues(x, y, z);
            m.transformPointInto(p, p);
            want.addPoint(p);
          }
        }
      }
      box.transformInto(m, box);
      expectVector3(box.min, want.min.x, want.min.y, want.min.z);
      expectVector3(box.max, want.max.x, want.max.y, want.max.z);
    }
  });

  test('an empty box transforms to an empty box', () {
    final out = Aabb3()..setValues(0, 0, 0, 1, 1, 1);
    Aabb3().transformInto(Matrix4.identity(), out);
    expect(out.isEmpty, isTrue);
  });
}
