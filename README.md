# Just Dart

Allocation-free math for Flutter games, shared by the Just engine packages.
Every type is mutable and works in place, so code that runs every frame
(physics, particles, culling, picking) doesn't add garbage-collection
pressure.

## Features

- **`Vector2` / `Vector3`**: mutable vectors with in-place arithmetic
  (`add`, `addScaled`, `normalize`, `crossInto`, ...) and `Offset`
  conversions for `Canvas`.
- **`Quaternion`**: 3-D rotations with axis-angle, slerp, vector rotation
  and Euler angles that round-trip the values an inspector shows.
- **`Matrix4`**: the same `vector_math` 64-bit class that Flutter exports,
  so the name never clashes. The `JustMatrix4` extension adds
  translate-rotate-scale builders, products, point and direction
  transforms, and y-down orthographic and perspective projections.
- **`Aabb3`, `Ray3`, `Plane`, `Frustum`**: bounds, picking rays and view
  frustum culling.
- **`Quadtree<T>`**: a 2-D broad phase that answers "what overlaps this
  rectangle?" queries.

Runs on Android, iOS, macOS, Windows, Linux and the web, compiled with
dart2js or dart2wasm. The package needs Flutter, because it uses `Offset`
and `Rect` from `dart:ui`.

## Getting started

Requires Dart `^3.11.0` and Flutter `>=3.41.0`.

```bash
flutter pub add just_dart
```

```dart
import 'package:just_dart/just_dart.dart';
```

## Conventions

- **Axes:** x right, **y down**, z into the screen. A positive turn about Z
  carries +X towards +Y, which is clockwise on screen, the same as
  `Canvas.rotate`.
- **Euler angles:** `q = qY · qX · qZ`, so Z is applied first, then X,
  then Y (Unity's order). A 2-D rotation is `(0, 0, angle)`.
- **Clip space:** x and y both run −1..1 (y down), and depth runs 0 (near)
  to 1 (far).
- **`Matrix4` storage** is column-major: element (row r, column c) is
  `storage[c * 4 + r]`.
- **Output parameters:** methods that take an `out` parameter write into it
  instead of allocating, and accept `out` being one of the inputs.
- **Equality** compares components exactly. The values are mutable, so
  don't change a vector or quaternion while it's a key in a `Set` or `Map`.

## Usage

### Vectors

```dart
final position = Vector2.zero();
final velocity = Vector2(3, 4);

const dt = 1 / 60;
position.addScaled(velocity, dt); // position += velocity * dt, no allocation

final speed = velocity.length; // 5.0
velocity.normalize(); // in place; a zero vector stays zero

final a = Vector3(1, 2, 3);
final normal = Vector3.zero();
a.crossInto(Vector3(0, 1, 0), normal); // a × (0, 1, 0), written into normal
final screen = a.toOffset(); // drops z, for Canvas APIs
```

### Rotations and transforms

```dart
final rotation = Quaternion.euler(0, 0, math.pi / 4); // 45° on screen
final world = Matrix4.zero()
  ..setFromTrs(Vector3(100, 50, 0), rotation, Vector3(2, 2, 1));

final p = Vector3(10, 0, 0);
world.transformPointInto(p, p); // in place

// Show Euler angles in an inspector: pass the last values as a hint, and
// they come back unchanged whenever they still describe the rotation.
final shown = Vector3(0, 0, 2 * math.pi + 0.3); // 377°
final q = Quaternion.euler(shown.x, shown.y, shown.z);
q.eulerInto(shown, hint: shown); // still exactly (0, 0, 2π + 0.3)
```

### Culling and picking

```dart
final projection = Matrix4.zero()
  ..setPerspectiveYDown(math.pi / 3, 16 / 9, 0.1, 1000);
final frustum = Frustum()..setFromViewProjection(projection);

final bounds = Aabb3()..setValues(-1, -1, 10, 1, 1, 12);
if (frustum.intersectsAabb(bounds)) {
  // draw it
}

final ray = Ray3()..setValues(0, 0, -10, 0, 0, 1);
final t = ray.intersectAabb(bounds); // distance along the ray, or null
final ground = ray.intersectZ(); // where it crosses the z = 0 plane
```

### Quadtree

```dart
final tree = Quadtree<String>(
  bounds: const Rect.fromLTWH(-500, -500, 1000, 1000),
  maxItems: 8,
  maxDepth: 6,
);

tree.insert('player', const Rect.fromLTWH(10, 20, 24, 24));
tree.insert('enemy_1', const Rect.fromLTWH(40, 35, 20, 20));

final nearby = <String>[];
tree.queryRect(const Rect.fromLTWH(0, 0, 80, 80), nearby);
print(nearby); // [player, enemy_1]
```

The tree stores each item once, so a query never returns an item twice.
Rectangles are captured when they're inserted: to move items, `clear()`
the tree and insert them again.

## Using it alongside `vector_math`

`Matrix4` is `vector_math`'s own class, so the two packages never disagree
about it. However, `vector_math` also defines `Vector2`, `Vector3`,
`Quaternion`, `Aabb3`, `Plane` and `Frustum`. If a file imports both
packages, prefix one of them:

```dart
import 'package:just_dart/just_dart.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
```

## API

| Type | What it is for |
| --- | --- |
| `Vector2`, `Vector3` | Mutable vectors |
| `Quaternion` | Rotations and Euler angles |
| `Matrix4`, `JustMatrix4` | 4×4 transforms and projections |
| `Aabb3` | Axis-aligned bounding boxes |
| `Ray3` | Rays for picking (plane, z-plane and box hits) |
| `Plane` | Signed-distance planes |
| `Frustum` | View frustum culling |
| `Quadtree<T>` | 2-D rectangle broad phase |

Everything is exported from `package:just_dart/just_dart.dart`.

## Development

From `packages/just_dart`:

```bash
flutter pub get
flutter test
flutter analyze
dart format .
```

## Contributing

- See [CONTRIBUTING.md](https://github.com/just-unknown-dev/just-dart/blob/main/CONTRIBUTING.md)
- See [CODE_OF_CONDUCT.md](https://github.com/just-unknown-dev/just-dart/blob/main/CODE_OF_CONDUCT.md)

## License

BSD-3-Clause. See [LICENSE](LICENSE).
