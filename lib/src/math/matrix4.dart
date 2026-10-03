/// 4×4 matrix helpers for the Just engine's own vector types.
///
/// The matrix class itself is `vector_math`'s 64-bit [Matrix4] — the very
/// class Flutter's `widgets`/`rendering` libraries export — so a file that
/// imports both Flutter and a Just package sees one `Matrix4`, never two.
/// Its storage is a column-major `Float64List`, which `Canvas.transform`
/// takes as is. This file adds what the engine needs on top of it, in terms
/// of the Just [Vector3] and [Quaternion], without allocating.
library;

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'quaternion.dart';
import 'vector3.dart';

/// Engine-side operations on [Matrix4].
///
/// Element (row r, column c) lives at `storage[c * 4 + r]`.
///
/// ## Clip space
///
/// The engine's clip space follows its world axes: x right, **y down**,
/// depth **0 (near) .. 1 (far)**. [setOrthographicYDown] and
/// [setPerspectiveYDown] build projections into it; a rendering backend with
/// a different convention applies its own fix-up matrix once.
extension JustMatrix4 on Matrix4 {
  /// Set to the transform that scales by [s], then rotates by [q], then
  /// translates by [p] (`T · R · S`).
  void setFromTrs(Vector3 p, Quaternion q, Vector3 s) {
    final m = storage;
    final x = q.x, y = q.y, z = q.z, w = q.w;
    final x2 = x + x, y2 = y + y, z2 = z + z;
    final xx = x * x2, xy = x * y2, xz = x * z2;
    final yy = y * y2, yz = y * z2, zz = z * z2;
    final wx = w * x2, wy = w * y2, wz = w * z2;
    final sx = s.x, sy = s.y, sz = s.z;
    m[0] = (1.0 - (yy + zz)) * sx;
    m[1] = (xy + wz) * sx;
    m[2] = (xz - wy) * sx;
    m[3] = 0.0;
    m[4] = (xy - wz) * sy;
    m[5] = (1.0 - (xx + zz)) * sy;
    m[6] = (yz + wx) * sy;
    m[7] = 0.0;
    m[8] = (xz + wy) * sz;
    m[9] = (yz - wx) * sz;
    m[10] = (1.0 - (xx + yy)) * sz;
    m[11] = 0.0;
    m[12] = p.x;
    m[13] = p.y;
    m[14] = p.z;
    m[15] = 1.0;
  }

  /// The 2-D fast path of [setFromTrs]: a turn of [angle] about Z, scale
  /// ([sx], [sy], [sz]) and translation ([px], [py], [pz]). One sin/cos.
  void setFromPlanarTrs(
    double px,
    double py,
    double pz,
    double angle,
    double sx,
    double sy,
    double sz,
  ) {
    final m = storage;
    final c = math.cos(angle), s = math.sin(angle);
    m[0] = c * sx;
    m[1] = s * sx;
    m[2] = 0.0;
    m[3] = 0.0;
    m[4] = -s * sy;
    m[5] = c * sy;
    m[6] = 0.0;
    m[7] = 0.0;
    m[8] = 0.0;
    m[9] = 0.0;
    m[10] = sz;
    m[11] = 0.0;
    m[12] = px;
    m[13] = py;
    m[14] = pz;
    m[15] = 1.0;
  }

  /// Set to `a · b` (apply [b] first). Safe when either is `this`.
  void setProduct(Matrix4 a, Matrix4 b) {
    final x = a.storage, y = b.storage, out = storage;
    final a00 = x[0], a01 = x[4], a02 = x[8], a03 = x[12];
    final a10 = x[1], a11 = x[5], a12 = x[9], a13 = x[13];
    final a20 = x[2], a21 = x[6], a22 = x[10], a23 = x[14];
    final a30 = x[3], a31 = x[7], a32 = x[11], a33 = x[15];
    final b00 = y[0], b01 = y[4], b02 = y[8], b03 = y[12];
    final b10 = y[1], b11 = y[5], b12 = y[9], b13 = y[13];
    final b20 = y[2], b21 = y[6], b22 = y[10], b23 = y[14];
    final b30 = y[3], b31 = y[7], b32 = y[11], b33 = y[15];
    out[0] = a00 * b00 + a01 * b10 + a02 * b20 + a03 * b30;
    out[4] = a00 * b01 + a01 * b11 + a02 * b21 + a03 * b31;
    out[8] = a00 * b02 + a01 * b12 + a02 * b22 + a03 * b32;
    out[12] = a00 * b03 + a01 * b13 + a02 * b23 + a03 * b33;
    out[1] = a10 * b00 + a11 * b10 + a12 * b20 + a13 * b30;
    out[5] = a10 * b01 + a11 * b11 + a12 * b21 + a13 * b31;
    out[9] = a10 * b02 + a11 * b12 + a12 * b22 + a13 * b32;
    out[13] = a10 * b03 + a11 * b13 + a12 * b23 + a13 * b33;
    out[2] = a20 * b00 + a21 * b10 + a22 * b20 + a23 * b30;
    out[6] = a20 * b01 + a21 * b11 + a22 * b21 + a23 * b31;
    out[10] = a20 * b02 + a21 * b12 + a22 * b22 + a23 * b32;
    out[14] = a20 * b03 + a21 * b13 + a22 * b23 + a23 * b33;
    out[3] = a30 * b00 + a31 * b10 + a32 * b20 + a33 * b30;
    out[7] = a30 * b01 + a31 * b11 + a32 * b21 + a33 * b31;
    out[11] = a30 * b02 + a31 * b12 + a32 * b22 + a33 * b32;
    out[15] = a30 * b03 + a31 * b13 + a32 * b23 + a33 * b33;
  }

  /// Write [input] as a point (w = 1) transformed by this into [out],
  /// with the perspective divide. A point that lands on w = 0 (the camera
  /// plane of a perspective matrix) has no finite image and is written
  /// undivided. Safe when `out == input`.
  void transformPointInto(Vector3 input, Vector3 out) {
    final m = storage;
    final x = input.x, y = input.y, z = input.z;
    final rx = m[0] * x + m[4] * y + m[8] * z + m[12];
    final ry = m[1] * x + m[5] * y + m[9] * z + m[13];
    final rz = m[2] * x + m[6] * y + m[10] * z + m[14];
    final rw = m[3] * x + m[7] * y + m[11] * z + m[15];
    if (rw == 1.0 || rw == 0.0) {
      out.setValues(rx, ry, rz);
    } else {
      final inv = 1.0 / rw;
      out.setValues(rx * inv, ry * inv, rz * inv);
    }
  }

  /// Write [input] as a direction (w = 0) transformed by this into [out].
  /// Safe when `out == input`.
  void transformDirectionInto(Vector3 input, Vector3 out) {
    final m = storage;
    final x = input.x, y = input.y, z = input.z;
    out.setValues(
      m[0] * x + m[4] * y + m[8] * z,
      m[1] * x + m[5] * y + m[9] * z,
      m[2] * x + m[6] * y + m[10] * z,
    );
  }

  /// Write this matrix's translation into [out].
  void translationInto(Vector3 out) {
    final m = storage;
    out.setValues(m[12], m[13], m[14]);
  }

  /// Orthographic projection into the engine's clip space: world x in
  /// [[left], [right]] → -1..1, y in [[top], [bottom]] → -1..1 (y down),
  /// z in [[near], [far]] → 0..1.
  void setOrthographicYDown(
    double left,
    double right,
    double top,
    double bottom,
    double near,
    double far,
  ) {
    assert(right != left && bottom != top && far != near, 'empty view box');
    final m = storage;
    final rl = 1.0 / (right - left);
    final bt = 1.0 / (bottom - top);
    final fn = 1.0 / (far - near);
    m[0] = 2.0 * rl;
    m[1] = 0.0;
    m[2] = 0.0;
    m[3] = 0.0;
    m[4] = 0.0;
    m[5] = 2.0 * bt;
    m[6] = 0.0;
    m[7] = 0.0;
    m[8] = 0.0;
    m[9] = 0.0;
    m[10] = fn;
    m[11] = 0.0;
    m[12] = -(right + left) * rl;
    m[13] = -(bottom + top) * bt;
    m[14] = -near * fn;
    m[15] = 1.0;
  }

  /// Perspective projection into the engine's clip space for a camera
  /// looking down +Z with +Y down: vertical field of view [fovY] (radians),
  /// [aspect] = width / height, depth [near] → 0 and [far] → 1.
  ///
  /// Needs `0 < fovY < π`, `aspect > 0` and `0 < near < far`.
  void setPerspectiveYDown(
    double fovY,
    double aspect,
    double near,
    double far,
  ) {
    assert(fovY > 0 && fovY < math.pi, 'fovY must be in (0, π): $fovY');
    assert(aspect > 0, 'aspect must be positive: $aspect');
    assert(near > 0 && far > near, 'needs 0 < near < far: $near, $far');
    final m = storage;
    final f = 1.0 / math.tan(fovY * 0.5);
    final range = far / (far - near);
    m[0] = f / aspect;
    m[1] = 0.0;
    m[2] = 0.0;
    m[3] = 0.0;
    m[4] = 0.0;
    m[5] = f;
    m[6] = 0.0;
    m[7] = 0.0;
    m[8] = 0.0;
    m[9] = 0.0;
    m[10] = range;
    m[11] = 1.0;
    m[12] = 0.0;
    m[13] = 0.0;
    m[14] = -near * range;
    m[15] = 0.0;
  }
}
