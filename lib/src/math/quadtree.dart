/// A lightweight axis-aligned quadtree for spatial queries.
library;

import 'package:flutter/painting.dart' show Rect;

/// A spatial quadtree that indexes items by their bounding rectangle.
///
/// Each item is stored once, in the smallest node whose bounds fully contain
/// its rectangle; an item that straddles a split line stays in the parent.
/// So [queryRect] never reports an item twice, and a large item (a
/// background, say) costs one entry, not one per leaf.
///
/// Rectangles are captured when inserted: to move an item, [clear] and
/// insert again.
class Quadtree<T> {
  /// World-space bounds of this node.
  final Rect bounds;

  /// Maximum items per leaf before subdividing.
  final int maxItems;

  /// Maximum tree depth.
  final int maxDepth;

  final int _depth;
  final List<_QuadEntry<T>> _items = [];
  List<Quadtree<T>>? _children;

  /// Create a quadtree covering [bounds].
  Quadtree({required this.bounds, this.maxItems = 16, this.maxDepth = 8})
    : _depth = 0;

  Quadtree._child({
    required this.bounds,
    required this.maxItems,
    required this.maxDepth,
    required int depth,
  }) : _depth = depth;

  /// Remove all items and collapse children.
  void clear() {
    _items.clear();
    _children = null;
  }

  /// Insert an [item] with [rect] bounds.
  ///
  /// Nothing is stored when [rect] is null or lies wholly outside [bounds];
  /// a rect that sticks out of [bounds] is kept, but only its part inside
  /// [bounds] can be found.
  void insert(T item, Rect? rect) {
    if (rect == null) return;
    if (!bounds.overlaps(rect)) return;
    _insert(_QuadEntry(item, rect));
  }

  void _insert(_QuadEntry<T> entry) {
    if (_children != null) {
      final child = _childContaining(entry.rect);
      if (child != null) {
        child._insert(entry);
      } else {
        _items.add(entry);
      }
      return;
    }

    _items.add(entry);

    if (_items.length > maxItems && _depth < maxDepth) {
      _subdivide();
    }
  }

  /// Append all items whose bounds intersect [region] into [result].
  ///
  /// Touching edges do not count as intersecting (see [Rect.overlaps]).
  void queryRect(Rect region, List<T> result) {
    if (!bounds.overlaps(region)) return;

    final items = _items;
    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      if (entry.rect.overlaps(region)) {
        result.add(entry.item);
      }
    }

    final children = _children;
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        children[i].queryRect(region, result);
      }
    }
  }

  /// The child whose bounds fully contain [rect], if any.
  Quadtree<T>? _childContaining(Rect rect) {
    final children = _children!;
    for (var i = 0; i < children.length; i++) {
      final b = children[i].bounds;
      if (rect.left >= b.left &&
          rect.right <= b.right &&
          rect.top >= b.top &&
          rect.bottom <= b.bottom) {
        return children[i];
      }
    }
    return null;
  }

  void _subdivide() {
    final mx = bounds.left + bounds.width / 2;
    final my = bounds.top + bounds.height / 2;
    final nextDepth = _depth + 1;

    _children = <Quadtree<T>>[
      Quadtree._child(
        bounds: Rect.fromLTRB(bounds.left, bounds.top, mx, my),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: nextDepth,
      ),
      Quadtree._child(
        bounds: Rect.fromLTRB(mx, bounds.top, bounds.right, my),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: nextDepth,
      ),
      Quadtree._child(
        bounds: Rect.fromLTRB(bounds.left, my, mx, bounds.bottom),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: nextDepth,
      ),
      Quadtree._child(
        bounds: Rect.fromLTRB(mx, my, bounds.right, bounds.bottom),
        maxItems: maxItems,
        maxDepth: maxDepth,
        depth: nextDepth,
      ),
    ];

    // Push down every item that fits wholly inside one child; the ones on
    // a split line stay here.
    final entries = List<_QuadEntry<T>>.of(_items);
    _items.clear();
    for (final entry in entries) {
      _insert(entry);
    }
  }
}

class _QuadEntry<T> {
  final T item;
  final Rect rect;

  _QuadEntry(this.item, this.rect);
}
