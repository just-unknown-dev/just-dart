// ignore_for_file: avoid_print
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:just_dart/just_dart.dart';

void main() {
  // 2-D movement, in place.
  final position = Vector2(12, 8);
  final velocity = Vector2(3, 4);
  const dt = 0.5;
  position.addScaled(velocity, dt);
  print('position: ${position.toOffset()}');

  // Broad phase: what is near the player?
  final tree = Quadtree<String>(
    bounds: const Rect.fromLTWH(-100, -100, 200, 200),
  );
  tree.insert('player', const Rect.fromLTWH(10, 12, 16, 16));
  tree.insert('enemy', const Rect.fromLTWH(28, 18, 16, 16));
  tree.insert('far away', const Rect.fromLTWH(80, 80, 8, 8));
  final nearby = <String>[];
  tree.queryRect(const Rect.fromLTWH(0, 0, 40, 40), nearby);
  print('nearby: $nearby');

  // A sprite's world transform: scale, then a 30° turn, then a move.
  final transform = Matrix4.zero()
    ..setFromTrs(
      Vector3(100, 50, 0),
      Quaternion.euler(0, 0, math.pi / 6),
      Vector3(2, 2, 1),
    );
  final corner = Vector3(8, 8, 0);
  transform.transformPointInto(corner, corner);
  print('corner in the world: $corner');

  // Cull with a perspective camera at the origin looking down +Z.
  final camera = Matrix4.zero()
    ..setPerspectiveYDown(math.pi / 3, 16 / 9, 0.1, 1000);
  final frustum = Frustum()..setFromViewProjection(camera);
  final ahead = Aabb3()..setValues(-1, -1, 10, 1, 1, 12);
  final behind = Aabb3()..setValues(-1, -1, -12, 1, 1, -10);
  print(
    'visible: ahead=${frustum.intersectsAabb(ahead)} '
    'behind=${frustum.intersectsAabb(behind)}',
  );

  // Pick: where does a ray from the camera hit the box?
  final ray = Ray3()..setValues(0, 0, 0, 0, 0, 1);
  print('ray hits the box at t=${ray.intersectAabb(ahead)}');
}
