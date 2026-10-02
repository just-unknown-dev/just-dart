/// Mutable unit quaternion for 3-D rotations.
library;

import 'dart:math' as math;

import 'vector3.dart';

/// A mutable rotation quaternion `(x, y, z, w)`, Hamilton convention.
///
/// A vector is rotated as `q · v · q⁻¹`; composing `a · b` applies `b`
/// first, then `a`. Rotations are right-handed about their axis, so in the
/// engine's world (X right, Y down, Z into the screen) a positive turn about
/// Z carries +X towards +Y — clockwise on screen, like `Canvas.rotate`.
///
/// ## Euler angles
///
/// There is exactly one Euler convention in the Just packages:
///
/// ```text
/// q = qY(y) · qX(x) · qZ(z)        R = Ry · Rx · Rz
/// ```
///
/// i.e. Z is applied first, then X, then Y, all about the fixed world axes
/// (the order Unity uses). A 2-D rotation is `(0, 0, angle)`.
///
/// Like [Vector3], every operation works in place so hot paths never
/// allocate; methods that take an `out` parameter are safe to alias.
class Quaternion {
  /// Vector part, x.
  double x;

  /// Vector part, y.
  double y;

  /// Vector part, z.
  double z;

  /// Scalar part.
  double w;

  /// Create from raw components (not normalised).
  Quaternion(this.x, this.y, this.z, this.w);

  /// The identity rotation.
  Quaternion.identity() : x = 0.0, y = 0.0, z = 0.0, w = 1.0;

  /// Copy constructor.
  Quaternion.copy(Quaternion other)
    : x = other.x,
      y = other.y,
      z = other.z,
      w = other.w;

  /// The rotation with Euler angles [ex], [ey], [ez] (radians).
  Quaternion.euler(double ex, double ey, double ez)
    : x = 0.0,
      y = 0.0,
      z = 0.0,
      w = 1.0 {
    setEuler(ex, ey, ez);
  }

  /// A rotation of [angle] radians about [axis] (need not be normalised).
  Quaternion.axisAngle(Vector3 axis, double angle)
    : x = 0.0,
      y = 0.0,
      z = 0.0,
      w = 1.0 {
    setAxisAngle(axis.x, axis.y, axis.z, angle);
  }

  // ── Setters ─────────────────────────────────────────────────────────────

  /// Set raw components.
  void setValues(double nx, double ny, double nz, double nw) {
    x = nx;
    y = ny;
    z = nz;
    w = nw;
  }

  /// Set to [other].
  void setFrom(Quaternion other) {
    x = other.x;
    y = other.y;
    z = other.z;
    w = other.w;
  }

  /// Set to the identity rotation.
  void setIdentity() {
    x = 0.0;
    y = 0.0;
    z = 0.0;
    w = 1.0;
  }

  /// Set to a rotation of [angle] radians about the axis `(ax, ay, az)`.
  /// A zero axis gives the identity.
  void setAxisAngle(double ax, double ay, double az, double angle) {
    final len = math.sqrt(ax * ax + ay * ay + az * az);
    if (len < 1e-12) {
      setIdentity();
      return;
    }
    final half = angle * 0.5;
    final s = math.sin(half) / len;
    x = ax * s;
    y = ay * s;
    z = az * s;
    w = math.cos(half);
  }

  /// Set to a rotation of [angle] radians about +Z — the 2-D rotation.
  void setRotationZ(double angle) {
    final half = angle * 0.5;
    x = 0.0;
    y = 0.0;
    z = math.sin(half);
    w = math.cos(half);
  }

  /// Set from Euler angles in radians: `q = qY(ey) · qX(ex) · qZ(ez)`.
  void setEuler(double ex, double ey, double ez) {
    final sa = math.sin(ex * 0.5), ca = math.cos(ex * 0.5);
    final sb = math.sin(ey * 0.5), cb = math.cos(ey * 0.5);
    final sc = math.sin(ez * 0.5), cc = math.cos(ez * 0.5);
    w = cb * ca * cc + sb * sa * sc;
    x = cb * sa * cc + sb * ca * sc;
    y = sb * ca * cc - cb * sa * sc;
    z = cb * ca * sc - sb * sa * cc;
  }

  /// Set from a rotation matrix given by its elements (row, column).
  ///
  /// The matrix must be orthonormal (a pure rotation).
  void setFromRotationElements(
    double m00,
    double m01,
    double m02,
    double m10,
    double m11,
    double m12,
    double m20,
    double m21,
    double m22,
  ) {
    final trace = m00 + m11 + m22;
    if (trace > 0.0) {
      final s = 0.5 / math.sqrt(trace + 1.0);
      w = 0.25 / s;
      x = (m21 - m12) * s;
      y = (m02 - m20) * s;
      z = (m10 - m01) * s;
    } else if (m00 > m11 && m00 > m22) {
      final s = 2.0 * math.sqrt(1.0 + m00 - m11 - m22);
      w = (m21 - m12) / s;
      x = 0.25 * s;
      y = (m01 + m10) / s;
      z = (m02 + m20) / s;
    } else if (m11 > m22) {
      final s = 2.0 * math.sqrt(1.0 + m11 - m00 - m22);
      w = (m02 - m20) / s;
      x = (m01 + m10) / s;
      y = 0.25 * s;
      z = (m12 + m21) / s;
    } else {
      final s = 2.0 * math.sqrt(1.0 + m22 - m00 - m11);
      w = (m10 - m01) / s;
      x = (m02 + m20) / s;
      y = (m12 + m21) / s;
      z = 0.25 * s;
    }
  }

  // ── Algebra ─────────────────────────────────────────────────────────────

  /// Set to `a · b` (apply [b], then [a]). Safe when either is `this`.
  void setProduct(Quaternion a, Quaternion b) {
    final ax = a.x, ay = a.y, az = a.z, aw = a.w;
    final bx = b.x, by = b.y, bz = b.z, bw = b.w;
    w = aw * bw - ax * bx - ay * by - az * bz;
    x = aw * bx + ax * bw + ay * bz - az * by;
    y = aw * by - ax * bz + ay * bw + az * bx;
    z = aw * bz + ax * by - ay * bx + az * bw;
  }

  /// `this = this · other` — apply [other] first, then the old `this`.
  void multiply(Quaternion other) => setProduct(this, other);

  /// `this = other · this` — apply the old `this` first, then [other].
  void premultiply(Quaternion other) => setProduct(other, this);

  /// Negate the vector part. For a unit quaternion this is the inverse.
  void conjugate() {
    x = -x;
    y = -y;
    z = -z;
  }

  /// Invert in place (works for non-unit quaternions too).
  void invert() {
    final n = lengthSquared;
    if (n < 1e-24) {
      setIdentity();
      return;
    }
    final inv = 1.0 / n;
    x = -x * inv;
    y = -y * inv;
    z = -z * inv;
    w = w * inv;
  }

  /// Squared norm.
  double get lengthSquared => x * x + y * y + z * z + w * w;

  /// Norm.
  double get length => math.sqrt(lengthSquared);

  /// Normalise in place. Returns the original length; a zero quaternion
  /// becomes the identity.
  double normalize() {
    final len = length;
    if (len < 1e-12) {
      setIdentity();
      return len;
    }
    final inv = 1.0 / len;
    x *= inv;
    y *= inv;
    z *= inv;
    w *= inv;
    return len;
  }

  /// Four-dimensional dot product.
  double dot(Quaternion other) =>
      x * other.x + y * other.y + z * other.z + w * other.w;

  /// Whether this is the identity rotation, within [epsilon].
  bool isIdentity([double epsilon = 1e-12]) =>
      x.abs() <= epsilon &&
      y.abs() <= epsilon &&
      z.abs() <= epsilon &&
      (w.abs() - 1.0).abs() <= epsilon;

  /// Whether this and [other] are the same rotation within [epsilon]
  /// (`q` and `-q` count as the same).
  bool sameRotation(Quaternion other, [double epsilon = 1e-9]) =>
      _close(other.x, other.y, other.z, other.w, epsilon);

  /// Whether `(qx, qy, qz, qw)` equals this or its negation, per component.
  bool _close(double qx, double qy, double qz, double qw, double epsilon) {
    final same =
        (qx - x).abs() <= epsilon &&
        (qy - y).abs() <= epsilon &&
        (qz - z).abs() <= epsilon &&
        (qw - w).abs() <= epsilon;
    if (same) return true;
    return (qx + x).abs() <= epsilon &&
        (qy + y).abs() <= epsilon &&
        (qz + z).abs() <= epsilon &&
        (qw + w).abs() <= epsilon;
  }

  /// Rotate [v] in place.
  void rotate(Vector3 v) => rotateInto(v, v);

  /// Write [input] rotated by this into [out]. Safe when `out == input`.
  void rotateInto(Vector3 input, Vector3 out) {
    // v' = v + 2w(q×v) + 2q×(q×v)
    final vx = input.x, vy = input.y, vz = input.z;
    final tx = 2.0 * (y * vz - z * vy);
    final ty = 2.0 * (z * vx - x * vz);
    final tz = 2.0 * (x * vy - y * vx);
    out.x = vx + w * tx + (y * tz - z * ty);
    out.y = vy + w * ty + (z * tx - x * tz);
    out.z = vz + w * tz + (x * ty - y * tx);
  }

  /// Set to the spherical interpolation from [a] (t = 0) to [b] (t = 1),
  /// along the shorter arc. Safe when `this` is [a] or [b].
  void setSlerp(Quaternion a, Quaternion b, double t) {
    var bx = b.x, by = b.y, bz = b.z, bw = b.w;
    var cosOmega = a.x * bx + a.y * by + a.z * bz + a.w * bw;
    if (cosOmega < 0.0) {
      cosOmega = -cosOmega;
      bx = -bx;
      by = -by;
      bz = -bz;
      bw = -bw;
    }
    double ka, kb;
    if (cosOmega > 0.9995) {
      // Nearly parallel: lerp, then normalise.
      ka = 1.0 - t;
      kb = t;
    } else {
      final omega = math.acos(cosOmega);
      final sinOmega = math.sin(omega);
      ka = math.sin((1.0 - t) * omega) / sinOmega;
      kb = math.sin(t * omega) / sinOmega;
    }
    final ax = a.x, ay = a.y, az = a.z, aw = a.w;
    x = ax * ka + bx * kb;
    y = ay * ka + by * kb;
    z = az * ka + bz * kb;
    w = aw * ka + bw * kb;
    normalize();
  }

  // ── Euler extraction ────────────────────────────────────────────────────

  /// Write this rotation's Euler angles (radians, see the class docs) into
  /// [out].
  ///
  /// Every rotation has two Euler triples (plus multiples of 2π). Without a
  /// [hint] the one with x in [-π/2, π/2] and y, z in (-π, π] is returned.
  /// With a [hint] — typically the angles the rotation was last set from —
  /// the triple closest to it is returned, each angle unwrapped towards the
  /// hint; and when `setEuler(hint)` already gives this rotation, [out] is
  /// exactly the hint. That is what lets an inspector show `370°` or
  /// `(180°, 0, 180°)` and get the same numbers back.
  ///
  /// Safe when `out == hint`.
  void eulerInto(Vector3 out, {Vector3? hint}) {
    if (hint != null && _reproduces(hint.x, hint.y, hint.z)) {
      out.setValues(hint.x, hint.y, hint.z);
      return;
    }
    final xx = x * x, yy = y * y, zz = z * z;
    final m12 = 2.0 * (y * z - x * w);
    final m02 = 2.0 * (x * z + y * w);
    final m22 = 1.0 - 2.0 * (xx + yy);
    final m10 = 2.0 * (x * y + z * w);
    final m11 = 1.0 - 2.0 * (xx + zz);
    final sx = -m12;
    double ex, ey, ez;
    if (sx.abs() < 0.9999999) {
      ex = math.asin(sx.clamp(-1.0, 1.0));
      ey = math.atan2(m02, m22);
      ez = math.atan2(m10, m11);
    } else {
      // Gimbal lock (x = ±90°): only y ∓ z is defined. Keep the hint's z
      // (0 without one) and solve y from it.
      final m00 = 1.0 - 2.0 * (yy + zz);
      final m20 = 2.0 * (x * z - y * w);
      final s = sx > 0 ? 1.0 : -1.0;
      ex = s * math.pi / 2;
      ez = hint?.z ?? 0.0;
      ey = math.atan2(-m20, m00) + s * ez;
      if (hint == null) ey = _wrapPi(ey);
    }
    if (hint == null) {
      out.setValues(ex, ey, ez);
      return;
    }
    // The other triple for the same rotation: (π - x, y + π, z + π).
    final ax1 = _near(ex, hint.x), ay1 = _near(ey, hint.y);
    final az1 = _near(ez, hint.z);
    final ax2 = _near(math.pi - ex, hint.x);
    final ay2 = _near(ey + math.pi, hint.y);
    final az2 = _near(ez + math.pi, hint.z);
    final d1 = _sq(ax1 - hint.x) + _sq(ay1 - hint.y) + _sq(az1 - hint.z);
    final d2 = _sq(ax2 - hint.x) + _sq(ay2 - hint.y) + _sq(az2 - hint.z);
    if (d2 < d1) {
      out.setValues(ax2, ay2, az2);
    } else {
      out.setValues(ax1, ay1, az1);
    }
  }

  /// Whether `setEuler(ex, ey, ez)` gives this rotation, component by
  /// component (a dot-product test cannot resolve angles below ~1e-8).
  bool _reproduces(double ex, double ey, double ez) {
    final sa = math.sin(ex * 0.5), ca = math.cos(ex * 0.5);
    final sb = math.sin(ey * 0.5), cb = math.cos(ey * 0.5);
    final sc = math.sin(ez * 0.5), cc = math.cos(ez * 0.5);
    final qw = cb * ca * cc + sb * sa * sc;
    final qx = cb * sa * cc + sb * ca * sc;
    final qy = sb * ca * cc - cb * sa * sc;
    final qz = cb * ca * sc - sb * sa * cc;
    return _close(qx, qy, qz, qw, 1e-12);
  }

  static double _sq(double v) => v * v;

  /// [angle] plus the multiple of 2π that brings it closest to [target].
  static double _near(double angle, double target) {
    const twoPi = 2 * math.pi;
    return angle + twoPi * ((target - angle) / twoPi).roundToDouble();
  }

  static double _wrapPi(double angle) => _near(angle, 0.0);

  // ── Object ──────────────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Quaternion &&
          x == other.x &&
          y == other.y &&
          z == other.z &&
          w == other.w;

  @override
  int get hashCode => Object.hash(x, y, z, w);

  @override
  String toString() => 'Quat($x, $y, $z, $w)';
}
