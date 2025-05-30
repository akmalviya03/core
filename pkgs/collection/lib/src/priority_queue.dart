// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'utils.dart';

/// A priority queue is a priority based work-list of elements.
///
/// The queue allows adding elements, and removing them again in priority order.
/// The same object can be added to the queue more than once.
/// There is no specified ordering for objects with the same priority
/// (where the `comparison` function returns zero).
///
/// Operations which care about object equality, [contains] and [remove],
/// use [Object.==] for testing equality.
/// In most situations this will be the same as identity ([identical]),
/// but there are types, like [String], where users can reasonably expect
/// distinct objects to represent the same value.
/// If elements override [Object.==], the `comparison` function must
/// always give equal objects the same priority,
/// otherwise [contains] or [remove] might not work correctly.
abstract class PriorityQueue<E> {
  /// Creates an empty priority queue.
  ///
  /// The created `PriorityQueue` is a plain [HeapPriorityQueue].
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  factory PriorityQueue([int Function(E, E)? comparison]) =
      HeapPriorityQueue<E>;

  /// Creates a new [HeapPriorityQueue] containing [elements].
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// Unlike [PriorityQueue.new], the [comparison] cannot be omitted.
  /// If the elements are comparable to each other, use [Comparable.compare]
  /// as the comparison function, or use a more specialized function
  /// if one is available.
  factory PriorityQueue.of(
    Iterable<E> elements,
    int Function(E, E) comparison,
  ) = HeapPriorityQueue<E>.of;

  /// Number of elements in the queue.
  int get length;

  /// Whether the queue is empty.
  bool get isEmpty;

  /// Whether the queue has any elements.
  bool get isNotEmpty;

  /// Checks if [object] is in the queue.
  ///
  /// Returns true if the element is found.
  ///
  /// Uses the [Object.==] of elements in the queue to check
  /// for whether they are equal to [object].
  /// Equal objects objects must have the same priority
  /// according to the comparison function.
  /// That is, if `a == b` then `comparison(a, b) == 0`.
  /// If that is not the case, this check might fail to find
  /// an object.
  bool contains(E object);

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation should be performed without copying or moving
  /// the elements, if at all possible.
  ///
  /// The elements are iterated in no particular order.
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  Iterable<E> get unorderedElements;

  /// Adds element to the queue.
  ///
  /// The element will become the next to be removed by [removeFirst]
  /// when all elements with higher priority have been removed.
  void add(E element);

  /// Adds all [elements] to the queue.
  void addAll(Iterable<E> elements);

  /// Returns the next element that will be returned by [removeFirst].
  ///
  /// The element is not removed from the queue.
  ///
  /// The queue must not be empty when this method is called.
  E get first;

  /// Removes and returns the element with the highest priority.
  ///
  /// Repeatedly calling this method, without adding element in between,
  /// is guaranteed to return elements in non-decreasing order as, specified by
  /// the `comparison` constructor parameter.
  ///
  /// The queue must not be empty when this method is called.
  E removeFirst();

  /// Removes an element of the queue that compares equal to [element].
  ///
  /// Returns true if an element is found and removed,
  /// and false if no equal element is found.
  ///
  /// If the queue contains more than one object equal to [element],
  /// only one of them is removed.
  ///
  /// Uses the [Object.==] of elements in the queue to check
  /// for whether they are equal to [element].
  /// Equal objects objects must have the same priority
  /// according to the `comparison` function.
  /// That is, if `a == b` then `comparison(a, b) == 0`.
  /// If that is not the case, this check might fail to find
  /// an object.
  bool remove(E element);

  /// Removes all the elements from this queue and returns them.
  ///
  /// The returned iterable has no specified order.
  Iterable<E> removeAll();

  /// Removes all the elements from this queue.
  void clear();

  /// Returns a list of the elements of this queue in priority order.
  ///
  /// The queue is not modified.
  ///
  /// The order is the order that the elements would be in if they were
  /// removed from this queue using [removeFirst].
  List<E> toList();

  /// Returns a list of the elements of this queue in no specific order.
  ///
  /// The queue is not modified.
  ///
  /// The order of the elements is implementation specific.
  /// The order may differ between different calls on the same queue.
  List<E> toUnorderedList();

  /// Return a comparator based set using the comparator of this queue.
  ///
  /// The queue is not modified.
  ///
  /// The returned [Set] is currently a [SplayTreeSet],
  /// but this may change as other ordered sets are implemented.
  ///
  /// The set contains all the elements of this queue.
  /// If an element occurs more than once in the queue,
  /// the set will contain it only once.
  Set<E> toSet();
}

/// Heap based priority queue.
///
/// The elements are kept in a heap structure,
/// where the element with the highest priority is immediately accessible,
/// and modifying a single element takes, on average,
/// logarithmic time in the number of elements.
///
/// * The [add] and [removeFirst] operations take amortized logarithmic time,
///   O(log(*N*)) where *N* is the number of elements, but may occasionally
///   take linear time when growing the capacity of the heap.
/// * The [addAll] operation works by doing repeated [add] operations.
///   May be more efficient in some cases.
/// * The [first] getter takes constant time, O(1).
/// * The [clear] and [removeAll] methods also take constant time, O(1).
/// * The [contains] and [remove] operations may need to search the entire
///   queue for the elements, taking O(*N*) time.
/// * The [toList] operation effectively sorts the elements,
///   taking O(n * log(*N*)) time.
/// * The [toUnorderedList] operation copies, but does not sort, the elements,
///   and is linear, O(n).
/// * The [toSet] operation effectively adds each element to the new
///   [SplayTreeSet], taking an expected O(n * log(*N*)) time.
///
/// The [comparison] function is used to order elements, with earlier elements
/// having higher priority. That is, elements are extracted from the queue
/// in ascending [comparison] order.
/// If two elements have the same priority, their ordering is unspecified
/// and may be arbitrary.
class HeapPriorityQueue<E> implements PriorityQueue<E> {
  /// The comparison being used to compare the priority of elements.
  final int Function(E, E) comparison;

  /// List implementation of a heap.
  List<E> _queue;

  /// Modification count.
  ///
  /// Used to detect concurrent modifications during iteration.
  /// Incremented whenever an element is added or removed.
  int _modificationCount = 0;

  /// Create a new priority queue.
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  HeapPriorityQueue([int Function(E, E)? comparison])
      : comparison = comparison ?? defaultCompare,
        _queue = <E>[];

  /// Creates a new priority queue containing [elements].
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  HeapPriorityQueue.of(Iterable<E> elements, this.comparison)
      : _queue = elements.toList() {
    _heapify();
  }

  /// Converts an unordered list of elements to a heap-ordered list of elements.
  ///
  /// Does so by ordering sub-trees iteratively, then bubbling their parent
  /// down into the two ordered subtrees.
  /// Trivially ignores the last half of elements, which have no children.
  /// Does a number of bubble-down steps that is bounded by the number
  /// of elements. Each bubble-down step does two comparisons.
  void _heapify() {
    // Last non-leaf node's index, negative for empty or one-element queue.
    var cursor = _queue.length ~/ 2 - 1;
    while (cursor >= 0) {
      _bubbleDown(_queue[cursor], cursor);
      cursor -= 1;
    }
  }

  @override
  void add(E element) {
    _modificationCount++;
    _queue.add(element);
    _bubbleUp(element, _queue.length - 1);
  }

  @override
  void addAll(Iterable<E> elements) {
    var endIndex = _queue.length;
    _queue.addAll(elements);
    var newLength = _queue.length;
    var addedCount = newLength - endIndex;
    if (addedCount == 0) return;
    _modificationCount++;
    // Approximation for when the time to bubble up all added elements,
    // taking approx. addedCount * (log2(newLength)-1) comparisons worst-case,
    // (bubble-up does one comparison per element per level),
    // is slower than just heapifying the entire heap, which does
    // newLength * 2 comparisons worst-case.
    // Uses `endIndex.bitLength` instead of `newLength.bitLength` because
    // if `addedCount` is greater than `newLength`, the bitLength won't matter
    // for any non-trivial heap, and if not, every added element is a leaf
    // element, so it only has to look at log2(endIndex) parents.
    if (addedCount * endIndex.bitLength >= newLength * 2) {
      _heapify();
      return;
    }
    for (var i = endIndex; i < newLength; i++) {
      _bubbleUp(_queue[i], i);
    }
  }

  @override
  void clear() {
    _modificationCount++;
    _queue.clear();
  }

  @override
  bool contains(E object) => _locate(object) >= 0;

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation is performed in the order they occur
  /// in the underlying heap structure.
  ///
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  @override
  Iterable<E> get unorderedElements => _UnorderedElementsIterable<E>(this);

  @override
  E get first => _queue.first;

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  bool get isNotEmpty => _queue.isNotEmpty;

  @override
  int get length => _queue.length;

  @override
  bool remove(E element) {
    var index = _locate(element);
    if (index < 0) return false;
    _modificationCount++;
    var last = _queue.removeLast();
    if (index < _queue.length) {
      var comp = comparison(last, element);
      if (comp <= 0) {
        _bubbleUp(last, index);
      } else {
        _bubbleDown(last, index);
      }
    }
    return true;
  }

  /// Removes all the elements from this queue and returns them.
  ///
  /// The [HeapPriorityQueue] returns a [List] of its elements,
  /// with no guaranteed order.
  ///
  /// If the elements are not needed, use [clear] instead.
  @override
  List<E> removeAll() {
    _modificationCount++;
    var result = _queue;
    _queue = <E>[];
    return result;
  }

  @override
  E removeFirst() {
    if (_queue.isEmpty) throw StateError('No element');
    _modificationCount++;
    var result = _queue.first;
    var last = _queue.removeLast();
    if (_queue.isNotEmpty) {
      _bubbleDown(last, 0);
    }
    return result;
  }

  @override
  List<E> toList() => _toUnorderedList()..sort(comparison);

  @override
  Set<E> toSet() => SplayTreeSet<E>(comparison)..addAll(_queue);

  @override
  List<E> toUnorderedList() => _toUnorderedList();

  List<E> _toUnorderedList() => _queue.toList();

  /// Returns some representation of the queue.
  ///
  /// The format isn't significant, and may change in the future.
  @override
  String toString() {
    return _queue.skip(0).toString();
  }

  /// Find the index of an object in the heap.
  ///
  /// Returns -1 if the object is not found.
  ///
  /// A matching object, `o`, must satisfy that
  /// `comparison(o, object) == 0 && o == object`.
  int _locate(E object) {
    if (_queue.isEmpty) return -1;
    // Count positions from one instead of zero. This gives the numbers
    // some nice properties. For example, all right children are odd,
    // their left sibling is even, and the parent is found by shifting
    // right by one.
    // Valid range for position is [1.._length], inclusive.
    var position = 1;
    // Pre-order depth first search, omit child nodes if the current
    // node has lower priority than [object], because all nodes lower
    // in the heap will also have lower priority.
    do {
      var index = position - 1;
      var element = _queue[index];
      var comp = comparison(element, object);
      if (comp <= 0) {
        if (comp == 0 && element == object) return index;
        // Element may be in subtree.
        // Continue with the left child, if it is there.
        var leftChildPosition = position * 2;
        if (leftChildPosition <= _queue.length) {
          position = leftChildPosition;
          continue;
        }
      }
      // Find the next right sibling or right ancestor sibling.
      do {
        while (position.isOdd) {
          // While position is a right child, go to the parent.
          position >>= 1;
        }
        // Then go to the right sibling of the left-child.
        position += 1;
      } while (
          position > _queue.length); // Happens if last element is a left child.
    } while (position != 1); // At root again. Happens for right-most element.
    return -1;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has higher priority than the
  /// parent, swap it with the parent.
  void _bubbleUp(E element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _queue[parentIndex];
      if (comparison(element, parent) > 0) break;
      _queue[index] = parent;
      index = parentIndex;
    }
    _queue[index] = element;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has lower priority than either child,
  /// swap it with the highest priority child.
  void _bubbleDown(E element, int index) {
    var rightChildIndex = index * 2 + 2;
    while (rightChildIndex < _queue.length) {
      var leftChildIndex = rightChildIndex - 1;
      var leftChild = _queue[leftChildIndex];
      var rightChild = _queue[rightChildIndex];
      var comp = comparison(leftChild, rightChild);
      int minChildIndex;
      E minChild;
      if (comp < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }
      comp = comparison(element, minChild);
      if (comp <= 0) {
        _queue[index] = element;
        return;
      }
      _queue[index] = minChild;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }
    var leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _queue.length) {
      var child = _queue[leftChildIndex];
      var comp = comparison(element, child);
      if (comp > 0) {
        _queue[index] = child;
        index = leftChildIndex;
      }
    }
    _queue[index] = element;
  }
}

/// Implementation of [HeapPriorityQueue.unorderedElements].
class _UnorderedElementsIterable<E> extends Iterable<E> {
  final HeapPriorityQueue<E> _queue;
  _UnorderedElementsIterable(this._queue);
  @override
  Iterator<E> get iterator => _UnorderedElementsIterator<E>(_queue);
}

class _UnorderedElementsIterator<E> implements Iterator<E> {
  final HeapPriorityQueue<E> _queue;
  final int _initialModificationCount;
  E? _current;
  int _index = -1;

  _UnorderedElementsIterator(this._queue)
      : _initialModificationCount = _queue._modificationCount;

  @override
  bool moveNext() {
    if (_initialModificationCount != _queue._modificationCount) {
      throw ConcurrentModificationError(_queue);
    }
    var nextIndex = _index + 1;
    if (0 <= nextIndex && nextIndex < _queue.length) {
      _current = _queue._queue[nextIndex];
      _index = nextIndex;
      return true;
    }
    _current = null;
    _index = -2;
    return false;
  }

  @override
  E get current =>
      _index < 0 ? throw StateError('No element') : (_current ?? null as E);
}
