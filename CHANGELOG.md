# Changelog

All notable changes to this package will be documented in this file.

## [0.2.0] - unreleased

The 3-D math the Just engine needs to be ready for 3-D. Everything works in
place, like `Vector3`, so hot paths never allocate.

### Added

- `Quaternion` — mutable rotation (Hamilton convention): axis-angle, Z turns,
  products, inverse, slerp, rotating vectors, conversion from a rotation
  matrix. **Euler angles** follow one documented convention,
  `q = qY · qX · qZ` (Z applied first, then X, then Y — Unity's order), and
  `eulerInto(out, hint:)` returns the triple nearest a hint, exactly the hint
  when it still describes the rotation, so edited angles round-trip.
- `Matrix4` — re-exported from `vector_math`'s 64-bit library. It is the same
  class Flutter's `widgets`/`rendering` libraries export, so importing
  Flutter and a Just package together never makes the name ambiguous, and its
  column-major `Float64List` goes straight to `Canvas.transform`.
  The `JustMatrix4` extension adds, for `Vector3`/`Quaternion`:
  `setFromTrs`, `setFromPlanarTrs` (2-D fast path), `setProduct`,
  `transformPointInto`, `transformDirectionInto`, `translationInto`, and the
  engine's clip-space projections `setOrthographicYDown` /
  `setPerspectiveYDown` (x right, y down, depth 0..1).
- `Aabb3`, `Ray3`, `Plane` and `Frustum` for bounds, picking rays and culling.
- `Vector3.crossInto` — cross product without allocating.

### Dependencies

- `vector_math: ^2.1.4` (only for `Matrix4`; Flutter already depends on it).

## [0.1.0] - 2026-05-11

Initial release of `just_dart`.

### Added

- `Vector2` for mutable 2-D vector math.
- `Vector3` for mutable 3-D vector math with `Offset` conversion helpers.
- `Quadtree<T>` for lightweight axis-aligned spatial queries.
- A shared export surface via `package:just_dart/just_dart.dart`.

