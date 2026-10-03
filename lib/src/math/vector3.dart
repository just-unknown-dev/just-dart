/// Mutable 3-D vector for performance-critical code paths.
///
/// Unlike Dart's [Offset], which is immutable and creates a new allocation
/// on every operation, [Vector3] is a mutable value holder. Physics, particles,
/// and collision systems use [Vector3] on the hot path to avoid per-frame GC
/// pressure.
///
/// The z-axis is ignored by the 2-D Canvas renderer (use [toOffset] to project
/// to XY). It carries depth/world-Z for 3-D work.
library;

import 'dart:math' as math;
import 'package:flutter/painting.dart' show Offset;

/// A mutable 3-D vector.
///
/// The in-place methods ([add], [addScaled], [crossInto], [normalize], ...)
/// never allocate; the operators, [cross] and [normalized] return new
/// vectors. Equality compares components exactly, and because the value is
/// mutable, a vector must not change while it is a key in a set or map.
class Vector3 {
  /// X component.
  double x;

  /// Y component.
  double y;

  /// Z component.
  double z;

  /// Create a vector from components.
  Vector3(this.x, this.y, this.z);

  /// The zero vector.
  Vector3.zero() : x = 0.0, y = 0.0, z = 0.0;

  /// Copy constructor.
  Vector3.copy(Vector3 other) : x = other.x, y = other.y, z = other.z;

  /// Create from 2-D components with z = 0 (convenience for 2-D migration).
  Vector3.fromXY(this.x, this.y) : z = 0.0;

  /// Create from a Dart [Offset] with z = 0.
  Vector3.fromOffset(Offset o) : x = o.dx, y = o.dy, z = 0.0;

  /// Project to an immutable [Offset] by discarding z (for Canvas APIs).
  Offset toOffset() => Offset(x, y);

  /// Set to [other].
  void setFrom(Vector3 other) {
    x = other.x;
    y = other.y;
    z = other.z;
  }

  /// Set to ([nx], [ny], [nz]).
  void setValues(double nx, double ny, double nz) {
    x = nx;
    y = ny;
    z = nz;
  }

  /// Set to zero.
  void setZero() {
    x = 0.0;
    y = 0.0;
    z = 0.0;
  }

  /// Add [other] in-place.
  void add(Vector3 other) {
    x += other.x;
    y += other.y;
    z += other.z;
  }

  /// Subtract [other] in-place.
  void sub(Vector3 other) {
    x -= other.x;
    y -= other.y;
    z -= other.z;
  }

  /// `this += other * scalar`.
  void addScaled(Vector3 other, double scalar) {
    x += other.x * scalar;
    y += other.y * scalar;
    z += other.z * scalar;
  }

  /// `this -= other * scalar`.
  void subScaled(Vector3 other, double scalar) {
    x -= other.x * scalar;
    y -= other.y * scalar;
    z -= other.z * scalar;
  }

  /// Multiply all components by [scalar].
  void scale(double scalar) {
    x *= scalar;
    y *= scalar;
    z *= scalar;
  }

  /// Negate all components.
  void negate() {
    x = -x;
    y = -y;
    z = -z;
  }

  /// Squared length (avoids sqrt).
  double get lengthSquared => x * x + y * y + z * z;

  /// Euclidean length.
  double get length => math.sqrt(x * x + y * y + z * z);

  /// Dot product.
  double dot(Vector3 other) => x * other.x + y * other.y + z * other.z;

  /// Cross product (returns a new vector).
  Vector3 cross(Vector3 other) => Vector3(
    y * other.z - z * other.y,
    z * other.x - x * other.z,
    x * other.y - y * other.x,
  );

  /// Write `this × other` into [out] without allocating. Safe when [out]
  /// is `this` or [other].
  void crossInto(Vector3 other, Vector3 out) {
    final cx = y * other.z - z * other.y;
    final cy = z * other.x - x * other.z;
    final cz = x * other.y - y * other.x;
    out.x = cx;
    out.y = cy;
    out.z = cz;
  }

  /// Distance squared to [other].
  double distanceToSquared(Vector3 other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return dx * dx + dy * dy + dz * dz;
  }

  /// Distance to [other].
  double distanceTo(Vector3 other) => math.sqrt(distanceToSquared(other));

  /// Normalise in-place. Returns the original length; a (near-)zero vector
  /// is left unchanged.
  double normalize() {
    final len = length;
    if (len > 1e-9) {
      final inv = 1.0 / len;
      x *= inv;
      y *= inv;
      z *= inv;
    }
    return len;
  }

  /// Return a normalised copy without mutating [this].
  ///
  /// A (near-)zero vector has no direction; it gives the unit x axis
  /// `(1, 0, 0)`, unlike [normalize], which leaves it at zero.
  Vector3 normalized() {
    final len = length;
    if (len > 1e-9) {
      final inv = 1.0 / len;
      return Vector3(x * inv, y * inv, z * inv);
    }
    return Vector3(1, 0, 0);
  }

  /// A new vector `this + other`.
  Vector3 operator +(Vector3 other) =>
      Vector3(x + other.x, y + other.y, z + other.z);

  /// A new vector `this - other`.
  Vector3 operator -(Vector3 other) =>
      Vector3(x - other.x, y - other.y, z - other.z);

  /// A new vector scaled by [s].
  Vector3 operator *(double s) => Vector3(x * s, y * s, z * s);

  /// A new vector divided by [s].
  Vector3 operator /(double s) => Vector3(x / s, y / s, z / s);

  /// A new, negated vector.
  Vector3 operator -() => Vector3(-x, -y, -z);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vector3 && x == other.x && y == other.y && z == other.z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vector3($x, $y, $z)';
}
