import 'package:just_dart/just_dart.dart';
import 'package:flutter/painting.dart';

void main() {
  final position = Vector2(12, 8);
  final velocity = Vector2(3, 4);
  const dt = 0.5;

  // Integrate a simple 2-D movement step.
  position.addScaled(velocity, dt);

  final direction = Vector3.fromOffset(position.toOffset());
  final cameraSpace = direction.normalized();

  final tree = Quadtree<String>(
    bounds: const Rect.fromLTWH(-100, -100, 200, 200),
  );
  tree.insert('player', const Rect.fromLTWH(10, 12, 16, 16));
  tree.insert('enemy', const Rect.fromLTWH(28, 18, 16, 16));

  final nearby = <String>[];
  tree.queryRect(const Rect.fromLTWH(0, 0, 40, 40), nearby);

  print('position: ${position.toOffset()}');
  print('direction: $direction');
  print('camera-space: $cameraSpace');
  print('nearby entities: $nearby');
}
