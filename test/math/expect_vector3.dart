// Shared expectations for the math tests (not a test file itself).

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

/// The default tolerance of [near] and [expectVector3].
const epsilon = 1e-9;

/// Matches a double within [eps] of [v].
Matcher near(double v, [double eps = epsilon]) => closeTo(v, eps);

/// Expects [v] to be (x, y, z) within [eps].
void expectVector3(
  Vector3 v,
  double x,
  double y,
  double z, [
  double eps = epsilon,
]) {
  expect(v.x, near(x, eps), reason: 'x of $v');
  expect(v.y, near(y, eps), reason: 'y of $v');
  expect(v.z, near(z, eps), reason: 'z of $v');
}
