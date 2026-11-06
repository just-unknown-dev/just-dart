/// Mutable ray in 3-D.
library;

import 'aabb3.dart';
import 'plane.dart';
import 'vector3.dart';

/// A half-line from [origin] along [direction]: the 3-D twin of the
/// engine's `Ray2D`.
///
/// [direction] need not be unit length; `t` values are in units of it, so
/// with a unit direction `t` is a distance.
class Ray3D {
  /// Start point.
  final Vector3 origin;

  /// Direction.
  final Vector3 direction;

  /// A ray from the origin along +Z (into the screen).
  Ray3D() : origin = Vector3.zero(), direction = Vector3(0, 0, 1);

  /// A ray from [origin] along [direction] (both copied).
  Ray3D.originDirection(Vector3 origin, Vector3 direction)
    : origin = Vector3.copy(origin),
      direction = Vector3.copy(direction);

  /// Set from raw components.
  void setValues(
    double ox,
    double oy,
    double oz,
    double dx,
    double dy,
    double dz,
  ) {
    origin.setValues(ox, oy, oz);
    direction.setValues(dx, dy, dz);
  }

  /// Set to [other].
  void setFrom(Ray3D other) {
    origin.setFrom(other.origin);
    direction.setFrom(other.direction);
  }

  /// Write `origin + direction · t` into [out].
  void atInto(double t, Vector3 out) => out.setValues(
    origin.x + direction.x * t,
    origin.y + direction.y * t,
    origin.z + direction.z * t,
  );

  /// Where the ray meets [plane], as `t` — null when it runs parallel or
  /// the plane is behind the origin.
  double? intersectPlane(Plane plane) {
    final denom = plane.normal.dot(direction);
    if (denom.abs() < 1e-12) return null;
    final t = -(plane.normal.dot(origin) + plane.constant) / denom;
    return t < 0.0 ? null : t;
  }

  /// Where the ray meets the plane `z = [z]` — the 2-D world plane at a
  /// depth — as `t`, or null (parallel, or behind the origin).
  double? intersectZ([double z = 0.0]) {
    if (direction.z.abs() < 1e-12) return null;
    final t = (z - origin.z) / direction.z;
    return t < 0.0 ? null : t;
  }

  /// Where the ray enters [box], as `t` (0 when the origin is inside), or
  /// null when it misses. Slab method.
  double? intersectAabb(Aabb3 box) {
    if (box.isEmpty) return null;
    var tMin = 0.0;
    var tMax = double.infinity;
    for (var axis = 0; axis < 3; axis++) {
      final o = axis == 0 ? origin.x : (axis == 1 ? origin.y : origin.z);
      final d = axis == 0
          ? direction.x
          : (axis == 1 ? direction.y : direction.z);
      final lo = axis == 0 ? box.min.x : (axis == 1 ? box.min.y : box.min.z);
      final hi = axis == 0 ? box.max.x : (axis == 1 ? box.max.y : box.max.z);
      if (d.abs() < 1e-12) {
        if (o < lo || o > hi) return null;
        continue;
      }
      var t1 = (lo - o) / d;
      var t2 = (hi - o) / d;
      if (t1 > t2) {
        final tmp = t1;
        t1 = t2;
        t2 = tmp;
      }
      if (t1 > tMin) tMin = t1;
      if (t2 < tMax) tMax = t2;
      if (tMin > tMax) return null;
    }
    return tMin;
  }

  @override
  String toString() => 'Ray3D($origin → $direction)';
}
