# Just Dart

`just_dart` provides small, reusable building blocks used across the Just ecosystem, with a focus on gameplay/runtime math and low-overhead spatial queries.

## Features

- Mutable `Vector2` for fast 2-D math (`addScaled`, `normalize`, dot/cross)
- Mutable `Vector3` for 3-D or 2.5-D data (`toOffset`, cross product, distance)
- Lightweight generic `Quadtree<T>` for axis-aligned rectangle spatial queries
- Flutter interop helpers (`Offset` conversions) for rendering pipelines

## Getting Started

Environment:

- Dart SDK `^3.11.0`

From the package root:

```bash
dart pub get
```

Import the package:

```dart
import 'package:just_dart/just_dart.dart';
```

## Usage

### Vector2 (mutable 2-D math)

```dart
import 'package:just_dart/just_dart.dart';

void main() {
	final velocity = Vector2(3, 4);
	final position = Vector2.zero();

	// Integrate: position += velocity * dt
	const dt = 0.016;
	position.addScaled(velocity, dt);

	final speed = velocity.length; // 5.0
	velocity.normalize();          // mutates velocity to unit length

	print('speed=$speed pos=${position.toOffset()} vel=$velocity');
}
```

### Vector3 (mutable 3-D math)

```dart
import 'package:just_dart/just_dart.dart';

void main() {
	final a = Vector3(1, 2, 3);
	final b = Vector3(0, 1, 0);

	final dot = a.dot(b);
	final normal = a.cross(b); // returns a new Vector3

	a.addScaled(Vector3(10, 0, 0), 0.1); // in-place mutation

	// For Flutter Canvas APIs (2-D projection)
	final screenPos = a.toOffset();

	print('dot=$dot normal=$normal screenPos=$screenPos');
}
```

### Quadtree (spatial broad-phase)

```dart
import 'package:flutter/painting.dart';
import 'package:just_dart/just_dart.dart';

void main() {
	final tree = Quadtree<String>(
		bounds: const Rect.fromLTWH(-500, -500, 1000, 1000),
		maxItems: 8,
		maxDepth: 6,
	);

	tree.insert('player', const Rect.fromLTWH(10, 20, 24, 24));
	tree.insert('enemy_1', const Rect.fromLTWH(40, 35, 20, 20));

	final nearby = <String>[];
	tree.queryRect(const Rect.fromLTWH(0, 0, 80, 80), nearby);

	print(nearby); // ['player', 'enemy_1']
}
```

## API Surface

- `Vector2`
- `Vector3`
- `Quadtree<T>`

Re-export path:

```dart
import 'package:just_dart/just_dart.dart';
```

## Development

From `packages/just_dart`:

```bash
dart pub get
dart test
dart analyze
```

## Contributing

- See [CONTRIBUTING.md](CONTRIBUTING.md)
- See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## License

BSD-3-Clause. See [LICENSE](LICENSE).
