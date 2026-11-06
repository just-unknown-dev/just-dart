/// The math feature: vectors, rotations, matrix transforms, bounds, rays,
/// planes, frustum culling and the 2-D broad phases.
library;

export 'vector2.dart';
export 'vector3.dart';
export 'quadtree.dart';
export 'spatial_hash_grid.dart';
export 'quaternion.dart';
export 'aabb3.dart';
export 'plane.dart';
export 'ray_3d.dart';
export 'frustum.dart';
export 'matrix4_transforms.dart';
// The 4×4 matrix is vector_math's 64-bit one — the same class Flutter's
// widgets and rendering libraries export — so importing Flutter and a Just
// package together never makes `Matrix4` ambiguous.
export 'package:vector_math/vector_math_64.dart' show Matrix4;
