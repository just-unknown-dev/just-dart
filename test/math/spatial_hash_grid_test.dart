// SpatialHashGrid: inserts, moves, removals and the three queries,
// then its edges (items inserted twice, items and queries the size
// of the world, bounds that aren't finite).

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

void main() {
  test('insert and query items', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    grid.insert('a', const Rect.fromLTWH(0, 0, 32, 32));
    grid.insert('b', const Rect.fromLTWH(100, 100, 32, 32));

    final results = grid.query(const Rect.fromLTWH(0, 0, 50, 50));
    expect(results, contains('a'));
    expect(results, isNot(contains('b')));
  });

  test('remove items', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    grid.insert('a', const Rect.fromLTWH(0, 0, 32, 32));
    grid.remove('a');
    expect(grid.isEmpty, isTrue);
  });

  test('update moves item to new position', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    grid.insert('a', const Rect.fromLTWH(0, 0, 32, 32));
    grid.update('a', const Rect.fromLTWH(200, 200, 32, 32));

    expect(grid.query(const Rect.fromLTWH(0, 0, 50, 50)), isNot(contains('a')));
    expect(grid.query(const Rect.fromLTWH(190, 190, 50, 50)), contains('a'));
  });

  test('queryPoint hits item at point', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    grid.insert('wall', const Rect.fromLTWH(10, 10, 50, 50));

    expect(grid.queryPoint(const Offset(30, 30)), contains('wall'));
    expect(grid.queryPoint(const Offset(5, 5)), isNot(contains('wall')));
  });

  test('queryRadius returns nearby items', () {
    final grid = SpatialHashGrid<int>(cellSize: 64);
    grid.insert(1, const Rect.fromLTWH(0, 0, 10, 10));
    grid.insert(2, const Rect.fromLTWH(300, 300, 10, 10));

    final hits = grid.queryRadius(const Offset(5, 5), 50);
    expect(hits, contains(1));
    expect(hits, isNot(contains(2)));
  });

  test('queryRadius does not include items just outside radius', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    // Item starts at (100,0); closest point to origin is (100,0); distance = 100
    grid.insert('far', const Rect.fromLTWH(100, 0, 10, 10));

    expect(grid.queryRadius(Offset.zero, 99), isNot(contains('far')));
    expect(grid.queryRadius(Offset.zero, 101), contains('far'));
  });

  test('clear removes all items', () {
    final grid = SpatialHashGrid<int>(cellSize: 32);
    for (int i = 0; i < 10; i++) {
      grid.insert(i, Rect.fromLTWH(i * 10.0, 0, 8, 8));
    }
    grid.clear();
    expect(grid.isEmpty, isTrue);
    expect(grid.cellCount, equals(0));
  });

  test('itemCount tracks correctly', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    grid.insert('a', const Rect.fromLTWH(0, 0, 32, 32));
    grid.insert('b', const Rect.fromLTWH(0, 0, 32, 32));
    expect(grid.itemCount, equals(2));
    grid.remove('a');
    expect(grid.itemCount, equals(1));
  });

  test('remove returns false for unknown item', () {
    final grid = SpatialHashGrid<String>(cellSize: 64);
    expect(grid.remove('ghost'), isFalse);
  });

  test('no hash collision for symmetric coordinates', () {
    // Previously (x*A) ^ ((y*B) >> 1) produced collisions for (x,y) and
    // (y,x) in common cases.  The fixed hash should give distinct values.
    final grid = SpatialHashGrid<int>(cellSize: 1);
    // Insert items at different grid positions and verify both are found.
    grid.insert(1, const Rect.fromLTWH(0, 1, 0.5, 0.5));
    grid.insert(2, const Rect.fromLTWH(1, 0, 0.5, 0.5));

    expect(grid.query(const Rect.fromLTWH(0, 1, 0.5, 0.5)), contains(1));
    expect(grid.query(const Rect.fromLTWH(1, 0, 0.5, 0.5)), contains(2));
  });

  test('inserting an item again moves it, leaving nothing behind', () {
    final grid = SpatialHashGrid<String>(cellSize: 10)
      ..insert('a', const Rect.fromLTWH(0, 0, 5, 5))
      ..insert('a', const Rect.fromLTWH(100, 100, 5, 5));

    expect(grid.query(const Rect.fromLTWH(0, 0, 5, 5)), isEmpty);
    expect(grid.query(const Rect.fromLTWH(100, 100, 5, 5)), {'a'});
    expect(grid.itemCount, 1);

    grid.remove('a');
    expect(grid.query(const Rect.fromLTWH(100, 100, 5, 5)), isEmpty);
    expect(grid.cellCount, 0);
  });

  test('a query the size of the world finds what it overlaps, at once', () {
    final grid = SpatialHashGrid<int>(cellSize: 1);
    for (var i = 0; i < 100; i++) {
      grid.insert(i, Rect.fromLTWH(i * 10.0, 0, 1, 1));
    }

    expect(grid.query(Rect.largest), hasLength(100));
    expect(
      grid.query(const Rect.fromLTRB(-1e300, -1e300, 1e300, 1e300)),
      hasLength(100),
    );
    expect(
      grid.query(const Rect.fromLTRB(double.negativeInfinity, -1, 25, 2)),
      {0, 1, 2},
    );
  });

  test('an item the size of the world is found and removed like any', () {
    final grid = SpatialHashGrid<String>(cellSize: 1)
      ..insert('world', const Rect.fromLTRB(-1e9, -1e9, 1e9, 1e9))
      ..insert('dot', const Rect.fromLTWH(5, 5, 1, 1));

    expect(grid.query(const Rect.fromLTWH(5, 5, 1, 1)), {'world', 'dot'});
    expect(grid.queryPoint(const Offset(-500, 300)), {'world'});
    expect(grid.queryRadius(const Offset(1e6, 1e6), 1), {'world'});
    expect(grid.itemCount, 2);

    expect(grid.remove('world'), isTrue);
    expect(grid.query(const Rect.fromLTWH(5, 5, 1, 1)), {'dot'});
    grid.clear();
    expect(grid.isEmpty, isTrue);
  });

  test('bounds that are not finite are refused', () {
    final grid = SpatialHashGrid<String>();
    expect(
      () => grid.insert('x', const Rect.fromLTRB(0, 0, double.infinity, 1)),
      throwsArgumentError,
    );
    expect(
      () => grid.insert('x', const Rect.fromLTRB(double.nan, 0, 1, 1)),
      throwsArgumentError,
    );
    expect(grid.isEmpty, isTrue);
  });
}
