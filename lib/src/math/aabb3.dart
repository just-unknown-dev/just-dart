/// Mutable axis-aligned bounding box in 3-D.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart' show Rect;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'vector3.dart';

/// A mutable axis-aligned box `[min, max]`.
///
/// A fresh box is *empty* (min = +∞, max = −∞) so points and boxes can be
/// accumulated into it with [addPoint] / [addBox].
class Aabb3 {
  /// Smallest corner.
  final Vector3 min;

  /// Largest corner.
  final Vector3 max;

  /// An empty box.
  Aabb3()
    : min = Vector3(double.infinity, double.infinity, double.infinity),
      max = Vector3(
        double.negativeInfinity,
        double.negativeInfinity,
        double.negativeInfinity,
      );

  /// A box from its corners (copied).
  Aabb3.minMax(Vector3 min, Vector3 max)
    : min = Vector3.copy(min),
      max = Vector3.copy(max);

  /// A box covering [rect] in x/y and [minZ]..[maxZ] in z — how a flat 2-D
  /// thing is seen in 3-D.
  Aabb3.fromRect(Rect rect, {double minZ = 0.0, double maxZ = 0.0})
    : min = Vector3(rect.left, rect.top, minZ),
      max = Vector3(rect.right, rect.bottom, maxZ);

  /// Copy constructor.
  Aabb3.copy(Aabb3 other)
    : min = Vector3.copy(other.min),
      max = Vector3.copy(other.max);

  /// Whether nothing has been added (any max below its min).
  bool get isEmpty => max.x < min.x || max.y < min.y || max.z < min.z;

  /// Reset to empty.
  void setEmpty() {
    min.setValues(double.infinity, double.infinity, double.infinity);
    max.setValues(
      double.negativeInfinity,
      double.negativeInfinity,
      double.negativeInfinity,
    );
  }

  /// Set to [other].
  void setFrom(Aabb3 other) {
    min.setFrom(other.min);
    max.setFrom(other.max);
  }

  /// Set from raw corners.
  void setValues(
    double minX,
    double minY,
    double minZ,
    double maxX,
    double maxY,
    double maxZ,
  ) {
    min.setValues(minX, minY, minZ);
    max.setValues(maxX, maxY, maxZ);
  }

  /// Set to [rect] in x/y, [minZ]..[maxZ] in z.
  void setFromRect(Rect rect, {double minZ = 0.0, double maxZ = 0.0}) =>
      setValues(rect.left, rect.top, minZ, rect.right, rect.bottom, maxZ);

  /// The x/y footprint as a [Rect] (z dropped).
  Rect toRect() => Rect.fromLTRB(min.x, min.y, max.x, max.y);

  /// Grow to contain the point (x, y, z).
  void addXYZ(double x, double y, double z) {
    if (x < min.x) min.x = x;
    if (y < min.y) min.y = y;
    if (z < min.z) min.z = z;
    if (x > max.x) max.x = x;
    if (y > max.y) max.y = y;
    if (z > max.z) max.z = z;
  }

  /// Grow to contain [p].
  void addPoint(Vector3 p) => addXYZ(p.x, p.y, p.z);

  /// Grow to contain [other].
  void addBox(Aabb3 other) {
    if (other.isEmpty) return;
    addPoint(other.min);
    addPoint(other.max);
  }

  /// Whether this and [other] overlap (touching counts).
  bool intersects(Aabb3 other) =>
      min.x <= other.max.x &&
      max.x >= other.min.x &&
      min.y <= other.max.y &&
      max.y >= other.min.y &&
      min.z <= other.max.z &&
      max.z >= other.min.z;

  /// Whether [p] is inside (on the surface counts).
  bool containsPoint(Vector3 p) =>
      p.x >= min.x &&
      p.x <= max.x &&
      p.y >= min.y &&
      p.y <= max.y &&
      p.z >= min.z &&
      p.z <= max.z;

  /// Write the centre into [out].
  void centerInto(Vector3 out) => out.setValues(
    (min.x + max.x) * 0.5,
    (min.y + max.y) * 0.5,
    (min.z + max.z) * 0.5,
  );

  /// Write the size into [out].
  void sizeInto(Vector3 out) =>
      out.setValues(max.x - min.x, max.y - min.y, max.z - min.z);

  /// Set [out] to the box around this one transformed by the affine [m]
  /// (Arvo's method — exact for the transformed corners). Safe when
  /// `out == this`.
  void transformInto(Matrix4 m, Aabb3 out) {
    if (isEmpty) {
      out.setEmpty();
      return;
    }
    final s = m.storage;
    final mnx = min.x, mny = min.y, mnz = min.z;
    final mxx = max.x, mxy = max.y, mxz = max.z;
    var loX = s[12], hiX = s[12];
    var loY = s[13], hiY = s[13];
    var loZ = s[14], hiZ = s[14];
    for (var col = 0; col < 3; col++) {
      final lo = col == 0 ? mnx : (col == 1 ? mny : mnz);
      final hi = col == 0 ? mxx : (col == 1 ? mxy : mxz);
      final ax = s[col * 4] * lo, bx = s[col * 4] * hi;
      final ay = s[col * 4 + 1] * lo, by = s[col * 4 + 1] * hi;
      final az = s[col * 4 + 2] * lo, bz = s[col * 4 + 2] * hi;
      loX += math.min(ax, bx);
      hiX += math.max(ax, bx);
      loY += math.min(ay, by);
      hiY += math.max(ay, by);
      loZ += math.min(az, bz);
      hiZ += math.max(az, bz);
    }
    out.setValues(loX, loY, loZ, hiX, hiY, hiZ);
  }

  @override
  String toString() => 'Aabb3($min, $max)';
}
