// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmark of efficiency of grapheme cluster operations.

import 'package:characters/characters.dart';

import '../test/src/text_samples.dart';

double bench(int Function() action, int ms) {
  var elapsed = 0;
  var count = 0;
  var stopwatch = Stopwatch()..start();
  do {
    count += action();
    elapsed = stopwatch.elapsedMilliseconds;
  } while (elapsed < ms);
  return count / elapsed;
}

int iterateIndicesOnly() {
  var graphemeClusters = 0;
  var char = Characters(hangul).iterator;
  while (char.moveNext()) {
    graphemeClusters++;
  }
  char = Characters(genesis).iterator;
  while (char.moveNext()) {
    graphemeClusters++;
  }
  return graphemeClusters;
}

int iterateStrings() {
  var codeUnits = 0;
  var char = Characters(hangul).iterator;
  while (char.moveNext()) {
    codeUnits += char.current.length;
  }
  char = Characters(genesis).iterator;
  while (char.moveNext()) {
    codeUnits += char.current.length;
  }
  return codeUnits;
}

int reverseStrings() {
  var revHangul = reverse(hangul);
  var rev2Hangul = reverse(revHangul);
  if (hangul != rev2Hangul || hangul == revHangul) {
    throw AssertionError('Bad reverse');
  }
  var revGenesis = reverse(genesis);
  var rev2Genesis = reverse(revGenesis);
  if (genesis != rev2Genesis || genesis == revGenesis) {
    throw AssertionError('Bad reverse');
  }

  return (hangul.length + genesis.length) * 2;
}

int replaceStrings() {
  var count = 0;
  {
    const language = '한글';
    assert(language.length == 6);
    var chars = Characters(hangul);
    var replaced = chars.replaceAll(
      Characters(language),
      Characters('Hangul!'),
    );
    count += replaced.string.length - hangul.length;
  }
  {
    var chars = Characters(genesis);
    var replaced = chars.replaceAll(Characters('And'), Characters('Also'));
    count += replaced.string.length - genesis.length;
  }
  return count;
}

String reverse(String input) {
  var chars = Characters(input);
  var buffer = StringBuffer();
  for (var it = chars.iteratorAtEnd; it.moveBack();) {
    buffer.write(it.current);
  }
  return buffer.toString();
}

void main(List<String> args) {
  var count = 1;
  if (args.isNotEmpty) count = int.tryParse(args[0]) ?? 1;

  // Warmup.
  bench(iterateIndicesOnly, 250);
  bench(iterateStrings, 250);
  bench(reverseStrings, 250);
  bench(replaceStrings, 250);

  var bestIterateIndices = 0.0;
  var bestIterateStrings = 0.0;
  var bestReverseStrings = 0.0;
  var bestReplaceStrings = 0.0;

  String toDigits(double d) {
    const n = 5;
    var s = d.round().toString();
    if (s.length >= n) return s;
    return d.toStringAsFixed(n - s.length);
  }

  for (var i = 0; i < count; i++) {
    var performance = bench(iterateIndicesOnly, 2000);
    print('Index Iteration: ${toDigits(performance)} gc/ms');
    if (performance > bestIterateIndices) bestIterateIndices = performance;

    performance = bench(iterateStrings, 2000);
    print('String Iteration: ${toDigits(performance)} cu/ms');
    if (performance > bestIterateStrings) bestIterateStrings = performance;

    performance = bench(reverseStrings, 2000);
    print('String Reversing: ${toDigits(performance)} cu/ms');
    if (performance > bestReverseStrings) bestReverseStrings = performance;

    performance = bench(replaceStrings, 2000);
    print('String Replacing: ${toDigits(performance)} changes/ms');
    if (performance > bestReplaceStrings) bestReplaceStrings = performance;
  }

  if (count > 1) {
    print('Best: ');
    print('Index Iteration: ${toDigits(bestIterateIndices)} gc/ms');
    print('String Iteration: ${toDigits(bestIterateStrings)} cu/ms');
    print('String Reversing: ${toDigits(bestReverseStrings)} cu/ms');
    print('String Replacing: ${toDigits(bestReplaceStrings)} changes/ms');
  }
}
