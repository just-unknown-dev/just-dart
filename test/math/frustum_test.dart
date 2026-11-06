import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

void main() {
  test('a frustum from an ortho camera keeps inside boxes only', () {
    final vp = Matrix4.zero()..setOrthographicYDown(0, 100, 0, 100, -10, 10);
    final f = Frustum()..setFromViewProjection(vp);
    expect(f.intersectsAabb(Aabb3()..setValues(10, 10, 0, 20, 20, 0)), isTrue);
    expect(
      f.intersectsAabb(Aabb3()..setValues(110, 10, 0, 120, 20, 0)),
      isFalse,
    );
    expect(
      f.intersectsAabb(Aabb3()..setValues(90, 90, 0, 120, 120, 0)),
      isTrue,
    );
    expect(f.containsPoint(Vector3(50, 50, 20)), isFalse);
    expect(f.planes.length, 6);
    expect(() => f.planes.add(Plane()), throwsUnsupportedError);
  });

  test('a perspective frustum culls behind, before near and past far', () {
    final vp = Matrix4.zero()..setPerspectiveYDown(math.pi / 2, 1, 1, 100);
    final f = Frustum()..setFromViewProjection(vp);
    expect(f.containsPoint(Vector3(0, 0, 50)), isTrue);
    expect(f.containsPoint(Vector3(0, 0, -5)), isFalse);
    expect(f.containsPoint(Vector3(0, 0, 0.5)), isFalse);
    expect(f.containsPoint(Vector3(0, 0, 101)), isFalse);
    expect(f.containsPoint(Vector3(60, 0, 50)), isFalse);
    expect(
      f.intersectsAabb(Aabb3()..setValues(-1, -1, -10, 1, 1, -5)),
      isFalse,
    );
    expect(f.intersectsAabb(Aabb3()..setValues(-1, -1, -10, 1, 1, 5)), isTrue);
    expect(f.intersectsAabb(Aabb3()), isFalse);
  });
}
