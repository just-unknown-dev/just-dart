# Changelog

All notable changes to this package will be documented in this file.

## [0.3.0] - 2026-11-05

Names that follow the engine's rules, a second 2-D broad phase, and tests laid out like the library.

### Breaking changes

- `Ray3` → `Ray3D`, the 3-D twin of the engine's `Ray2D`. Its file is `ray_3d.dart`, and `toString()` prints `Ray3D(...)`.
- The `Matrix4` extension `JustMatrix4` → `Matrix4Transforms` (extensions are named `<On><Feature>`). Its file is `matrix4_transforms.dart`. Member calls are unchanged; only code that names the extension (a `show` list, or an explicit `JustMatrix4(m).…`) changes.

### Added

- `SpatialHashGrid<T>`, moved here from just_tiled, where nothing used it: a uniform-grid broad phase beside `Quadtree<T>`, with `insert`, `update`, `remove`, `query`, `queryPoint` and `queryRadius`.
- README: a "Names" section. Math value types keep vector_math's digit (`Vector2`, `Vector3`, `Matrix4`, `Aabb3`); a type with a 2-D twin elsewhere in the engine takes the `2D`/`3D` tag (`Ray3D` beside `Ray2D`).

### Changed

- Tests mirror `lib/src`: one file per source file under `test/math/`. New tests cover `Quaternion.premultiply` and `conjugate`; `Aabb3.minMax`, `setFromRect`, `addBox` (with an empty box), `intersects`, `centerInto` and `sizeInto`; `Plane.normalConstant` and `setFromPointNormal`; and `Ray3D.originDirection`.
- `test/library_layout_test.dart` guards the layout: every file exported or `@internal`, only barrels export, no flat files in `lib/src`, no import loops between features.
- The library doc says what the package is.

## [0.2.0] - 2026-10-03

The 3-D math the Just engine needs to be ready for 3-D. Everything works in place, like `Vector3`, so hot paths never allocate.

### Added

- `Quaternion` — mutable rotation (Hamilton convention): axis-angle, Z turns, products, inverse, slerp, rotating vectors, conversion from a rotation matrix. **Euler angles** follow one documented convention, `q = qY · qX · qZ` (Z applied first, then X, then Y — Unity's order), and `eulerInto(out, hint:)` returns the triple nearest a hint, exactly the hint when it still describes the rotation, so edited angles round-trip.
- `Matrix4` — re-exported from `vector_math`'s 64-bit library. It is the same class Flutter's `widgets`/`rendering` libraries export, so importing Flutter and a Just package together never makes the name ambiguous, and its column-major `Float64List` goes straight to `Canvas.transform`. The `JustMatrix4` extension adds, for `Vector3`/`Quaternion`: `setFromTrs`, `setFromPlanarTrs` (2-D fast path), `setProduct`, `transformPointInto`, `transformDirectionInto`, `translationInto`, and the engine's clip-space projections `setOrthographicYDown` / `setPerspectiveYDown` (x right, y down, depth 0..1).
- `Aabb3`, `Ray3`, `Plane` and `Frustum` for bounds, picking rays and culling.
- `Vector3.crossInto` — cross product without allocating.

### Changed

- `Quadtree` stores each item once, in the smallest node that fully contains it; an item on a split line stays in the parent. Queries no longer return an item more than once, and a large item is no longer copied into every leaf (17 world-sized items among 200 small ones used to give 12,227 results for 217 items). Building is about twice as fast; with a few world-sized items, queries return half the hits and run 17% faster.
- `toString()` of `Vector2`, `Vector3` and `Quaternion` prints the class name: `Vector3(1.0, 2.0, 3.0)`, not `Vec3(1.0, 2.0, 3.0)`.
- `Frustum.planes` is a fixed-length list.
- `setOrthographicYDown` and `setPerspectiveYDown` assert (in debug builds) on inputs with no projection: an empty view box, `near <= 0`, `far <= near`, `aspect <= 0` or `fovY` outside (0, π).
- Requires Flutter `>=3.41.0`. The old `>=1.17.0` was never reachable with `sdk: ^3.11.0`.

### Fixed

- `Quaternion.eulerInto` near x = ±90°: without a matching hint, x snapped to the pole up to 4.5e-4 rad (about 0.026°) early, so 89.98° read back as 90° and the angles no longer described the rotation. x now comes from `atan2`, and the gimbal-lock branch only applies within 1e-8 of the pole.
- Documented the edge cases: `normalize()` leaves a zero vector at zero while `normalized()` returns the unit x axis, equality on mutable values, `transformPointInto` on w = 0, and planes with a zero normal.

### Dependencies

- `vector_math: ^2.1.4` (only for `Matrix4`; Flutter already depends on it).
- Tests use `flutter_test` instead of `test`, so they resolve against the versions the Flutter SDK pins.

## [0.1.0] - 2026-05-11

Initial release of `just_dart`.

### Added

- `Vector2` for mutable 2-D vector math.
- `Vector3` for mutable 3-D vector math with `Offset` conversion helpers.
- `Quadtree<T>` for lightweight axis-aligned spatial queries.
- A shared export surface via `package:just_dart/just_dart.dart`.

