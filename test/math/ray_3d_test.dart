import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

import 'expect_vector3.dart';

void main() {
  test('rays meet planes and boxes', () {
    final ray = Ray3D()..setValues(5, 5, -10, 0, 0, 1);
    expect(ray.intersectZ(), 10);
    expect(ray.intersectPlane(Plane()), near(10));
    final hit = Vector3.zero();
    ray.atInto(10, hit);
    expectVector3(hit, 5, 5, 0);

    final box = Aabb3()..setValues(0, 0, -1, 10, 10, 1);
    expect(ray.intersectAabb(box), near(9));
    ray.origin.setValues(20, 20, -10);
    expect(ray.intersectAabb(box), isNull);
    // Behind the origin.
    ray.setValues(0, 0, 5, 0, 0, 1);
    expect(ray.intersectZ(), isNull);
  });

  test('a ray starting inside a box hits it at 0', () {
    final ray = Ray3D()..setValues(5, 5, 0, 1, 0, 0);
    expect(ray.intersectAabb(Aabb3()..setValues(0, 0, -1, 10, 10, 1)), 0);
    expect(ray.intersectAabb(Aabb3()), isNull);
    expect(ray.intersectPlane(Plane()), isNull); // parallel to z = 0
  });

  test('originDirection copies both vectors; setFrom copies a ray', () {
    final origin = Vector3(1, 2, 3);
    final direction = Vector3(0, 0, -1);
    final ray = Ray3D.originDirection(origin, direction);
    origin.setValues(0, 0, 0);
    direction.setValues(1, 0, 0);
    expectVector3(ray.origin, 1, 2, 3);
    expectVector3(ray.direction, 0, 0, -1);
    expect(ray.intersectZ(), near(3));

    final copy = Ray3D()..setFrom(ray);
    expectVector3(copy.origin, 1, 2, 3);
    expectVector3(copy.direction, 0, 0, -1);
  });

  test('a default ray starts at the origin and points into the screen', () {
    final ray = Ray3D();
    expectVector3(ray.origin, 0, 0, 0);
    expectVector3(ray.direction, 0, 0, 1);
    expect(ray.toString(), startsWith('Ray3D('));
  });
}
