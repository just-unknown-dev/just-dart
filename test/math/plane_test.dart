import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

import 'expect_vector3.dart';

void main() {
  test('planes normalise and measure signed distance', () {
    final plane = Plane.pointNormal(Vector3(0, 0, 5), Vector3(0, 0, 2));
    expectVector3(plane.normal, 0, 0, 1);
    expect(plane.distanceTo(Vector3(0, 0, 8)), near(3));
    expect(plane.distanceToXYZ(0, 0, 2), near(-3));
    final scaled = Plane()..setCoefficients(0, 2, 0, -4);
    expectVector3(scaled.normal, 0, 1, 0);
    expect(scaled.constant, near(-2));
  });

  test('normalConstant normalises the normal and scales the constant', () {
    final normal = Vector3(0, 3, 4);
    final plane = Plane.normalConstant(normal, 10);
    expectVector3(plane.normal, 0, 0.6, 0.8);
    expect(plane.constant, near(2));
    // The normal was copied, not kept.
    expectVector3(normal, 0, 3, 4);
    // On the plane: 0.6·y + 0.8·z + 2 = 0.
    expect(plane.distanceToXYZ(0, 0, -2.5), near(0));
  });

  test('setFromPointNormal sets the plane through the point', () {
    final plane = Plane()
      ..setFromPointNormal(Vector3(1, 2, 3), Vector3(-2, 0, 0));
    expectVector3(plane.normal, -1, 0, 0);
    expect(plane.constant, near(1));
    expect(plane.distanceTo(Vector3(1, 50, -7)), near(0));
    expect(plane.distanceTo(Vector3(0, 0, 0)), near(1));
  });

  test('a zero normal is left as is, so distance is the constant', () {
    final plane = Plane()..setCoefficients(0, 0, 0, 5);
    expectVector3(plane.normal, 0, 0, 0);
    expect(plane.distanceToXYZ(9, 9, 9), 5);
  });

  test('the default plane is z = 0 facing +Z', () {
    final plane = Plane();
    expect(plane.distanceToXYZ(0, 0, 4), near(4));
    expect(plane.toString(), startsWith('Plane('));
  });
}
