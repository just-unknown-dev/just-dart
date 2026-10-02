/// Mutable plane in 3-D.
library;

import 'dart:math' as math;

import 'vector3.dart';

/// The plane of points `p` with `normal · p + constant = 0`.
///
/// The side the normal points to is "in front": [distanceTo] is positive
/// there. The normal is kept unit length by the constructors and
/// [normalize].
class Plane {
  /// Unit normal.
  final Vector3 normal;

  /// Signed offset: `-normal · (any point on the plane)`.
  double constant;

  /// The plane z = 0, facing +Z (into the screen) — the 2-D world plane.
  Plane() : normal = Vector3(0, 0, 1), constant = 0.0;

  /// A plane from a normal (normalised here) and constant.
  Plane.normalConstant(Vector3 normal, this.constant)
    : normal = Vector3.copy(normal) {
    normalize();
  }

  /// The plane through [point] facing [normal] (normalised here).
  Plane.pointNormal(Vector3 point, Vector3 normal)
    : normal = Vector3.copy(normal),
      constant = 0.0 {
    this.normal.normalize();
    constant = -this.normal.dot(point);
  }

  /// Set to the plane through [point] facing [normal] (normalised here).
  void setFromPointNormal(Vector3 point, Vector3 normal) {
    this.normal.setFrom(normal);
    this.normal.normalize();
    constant = -this.normal.dot(point);
  }

  /// Set from raw coefficients `a·x + b·y + c·z + d = 0`, normalising.
  void setCoefficients(double a, double b, double c, double d) {
    normal.setValues(a, b, c);
    constant = d;
    normalize();
  }

  /// Make the normal unit length, scaling [constant] with it.
  void normalize() {
    final len = math.sqrt(
      normal.x * normal.x + normal.y * normal.y + normal.z * normal.z,
    );
    if (len < 1e-12) return;
    final inv = 1.0 / len;
    normal.scale(inv);
    constant *= inv;
  }

  /// Signed distance from [p] (positive in front).
  double distanceTo(Vector3 p) => normal.dot(p) + constant;

  /// Signed distance from (x, y, z).
  double distanceToXYZ(double x, double y, double z) =>
      normal.x * x + normal.y * y + normal.z * z + constant;

  @override
  String toString() => 'Plane($normal, $constant)';
}
