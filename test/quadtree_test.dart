import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_dart/just_dart.dart';

const _world = Rect.fromLTWH(0, 0, 1000, 1000);

List<T> _query<T>(Quadtree<T> tree, Rect region) {
  final out = <T>[];
  tree.queryRect(region, out);
  return out;
}

void main() {
  group('Quadtree', () {
    test('finds what overlaps the region and nothing else', () {
      final tree = Quadtree<String>(
        bounds: const Rect.fromLTWH(-500, -500, 1000, 1000),
        maxItems: 8,
        maxDepth: 6,
      );
      tree.insert('player', const Rect.fromLTWH(10, 20, 24, 24));
      tree.insert('enemy_1', const Rect.fromLTWH(40, 35, 20, 20));
      tree.insert('far', const Rect.fromLTWH(400, 400, 10, 10));
      expect(
        _query(tree, const Rect.fromLTWH(0, 0, 80, 80)),
        unorderedEquals(['player', 'enemy_1']),
      );
    });

    test('matches a brute-force scan once it has subdivided', () {
      final rnd = math.Random(42);
      final tree = Quadtree<int>(bounds: _world, maxItems: 4);
      final rects = <Rect>[];
      for (var i = 0; i < 500; i++) {
        final r = Rect.fromLTWH(
          rnd.nextDouble() * 980,
          rnd.nextDouble() * 980,
          1 + rnd.nextDouble() * 60,
          1 + rnd.nextDouble() * 60,
        );
        rects.add(r);
        tree.insert(i, r);
      }
      for (var q = 0; q < 50; q++) {
        final region = Rect.fromLTWH(
          rnd.nextDouble() * 900,
          rnd.nextDouble() * 900,
          rnd.nextDouble() * 200,
          rnd.nextDouble() * 200,
        );
        final want = [
          for (var i = 0; i < rects.length; i++)
            if (rects[i].overlaps(region)) i,
        ];
        final got = _query(tree, region);
        expect(got, unorderedEquals(want));
        expect(got.length, got.toSet().length, reason: 'no duplicates');
      }
    });

    test('an item on a split line is reported once', () {
      final tree = Quadtree<String>(bounds: _world, maxItems: 1);
      tree.insert('a', const Rect.fromLTWH(10, 10, 5, 5));
      tree.insert('b', const Rect.fromLTWH(900, 900, 5, 5));
      tree.insert('centre', const Rect.fromLTWH(490, 490, 20, 20));
      expect(_query(tree, _world), unorderedEquals(['a', 'b', 'centre']));
    });

    test('large items are stored once, not copied into every leaf', () {
      final tree = Quadtree<int>(bounds: _world);
      for (var i = 0; i < 17; i++) {
        tree.insert(-1 - i, _world);
      }
      final rnd = math.Random(1);
      for (var i = 0; i < 200; i++) {
        tree.insert(
          i,
          Rect.fromLTWH(rnd.nextDouble() * 990, rnd.nextDouble() * 990, 5, 5),
        );
      }
      final all = _query(tree, _world);
      expect(all.length, 217);
      expect(all.toSet().length, 217);
    });

    test('ignores null and outside rects, keeps ones sticking out', () {
      final tree = Quadtree<String>(bounds: const Rect.fromLTWH(0, 0, 10, 10));
      tree.insert('null', null);
      tree.insert('outside', const Rect.fromLTWH(20, 20, 1, 1));
      tree.insert('edge', const Rect.fromLTWH(8, 8, 5, 5));
      expect(_query(tree, const Rect.fromLTWH(-100, -100, 1000, 1000)), [
        'edge',
      ]);
    });

    test('touching edges do not count', () {
      final tree = Quadtree<String>(bounds: _world);
      tree.insert('box', const Rect.fromLTWH(0, 0, 10, 10));
      expect(_query(tree, const Rect.fromLTWH(10, 0, 10, 10)), isEmpty);
      expect(_query(tree, const Rect.fromLTWH(9, 0, 10, 10)), ['box']);
    });

    test('maxDepth bounds the tree for many items in one spot', () {
      final tree = Quadtree<int>(bounds: _world, maxItems: 2, maxDepth: 3);
      for (var i = 0; i < 100; i++) {
        tree.insert(i, const Rect.fromLTWH(1, 1, 1, 1));
      }
      expect(_query(tree, const Rect.fromLTWH(0, 0, 5, 5)).length, 100);
    });

    test('clear empties the tree', () {
      final tree = Quadtree<int>(bounds: _world, maxItems: 1);
      for (var i = 0; i < 10; i++) {
        tree.insert(i, Rect.fromLTWH(i * 90.0, i * 90.0, 5, 5));
      }
      tree.clear();
      expect(_query(tree, _world), isEmpty);
      tree.insert(1, const Rect.fromLTWH(1, 1, 1, 1));
      expect(_query(tree, _world), [1]);
    });
  });
}
