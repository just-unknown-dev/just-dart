/// View frustum for culling.
library;

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'aabb3.dart';
import 'plane.dart';
import 'vector3.dart';

/// The six planes bounding what a camera sees, each facing inwards.
///
/// Built from a view-projection matrix into the engine's clip space
/// (x, y in −1..1, depth 0..1 — see `JustMatrix4`).
class Frustum {
  /// Left, right, top, bottom, near, far (a fixed-length list).
  final List<Plane> planes = List.generate(6, (_) => Plane(), growable: false);

  /// An empty-bounded frustum; call [setFromViewProjection].
  Frustum();

  /// Set from a view-projection matrix (Gribb–Hartmann extraction).
  void setFromViewProjection(Matrix4 viewProjection) {
    final m = viewProjection.storage;
    // Row r of the matrix is (m[r], m[4 + r], m[8 + r], m[12 + r]).
    final r0x = m[0], r0y = m[4], r0z = m[8], r0w = m[12];
    final r1x = m[1], r1y = m[5], r1z = m[9], r1w = m[13];
    final r2x = m[2], r2y = m[6], r2z = m[10], r2w = m[14];
    final r3x = m[3], r3y = m[7], r3z = m[11], r3w = m[15];
    planes[0].setCoefficients(r3x + r0x, r3y + r0y, r3z + r0z, r3w + r0w);
    planes[1].setCoefficients(r3x - r0x, r3y - r0y, r3z - r0z, r3w - r0w);
    planes[2].setCoefficients(r3x + r1x, r3y + r1y, r3z + r1z, r3w + r1w);
    planes[3].setCoefficients(r3x - r1x, r3y - r1y, r3z - r1z, r3w - r1w);
    planes[4].setCoefficients(r2x, r2y, r2z, r2w);
    planes[5].setCoefficients(r3x - r2x, r3y - r2y, r3z - r2z, r3w - r2w);
  }

  /// Whether [p] is inside (on a plane counts).
  bool containsPoint(Vector3 p) {
    for (var i = 0; i < 6; i++) {
      if (planes[i].distanceTo(p) < 0.0) return false;
    }
    return true;
  }

  /// Whether [box] is at least partly inside. Conservative: a box near a
  /// corner may pass without truly overlapping, never the reverse.
  bool intersectsAabb(Aabb3 box) {
    if (box.isEmpty) return false;
    for (var i = 0; i < 6; i++) {
      final plane = planes[i];
      final n = plane.normal;
      // The box corner furthest along the plane's normal.
      final px = n.x >= 0 ? box.max.x : box.min.x;
      final py = n.y >= 0 ? box.max.y : box.min.y;
      final pz = n.z >= 0 ? box.max.z : box.min.z;
      if (plane.distanceToXYZ(px, py, pz) < 0.0) return false;
    }
    return true;
  }
}
