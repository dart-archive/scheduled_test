// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

void main() {
  expectTestPasses('file().create() creates a file', () {
    scheduleSandbox();

    d.file('name.txt', 'contents').create();

    schedule(() {
      expect(new File(path.join(sandbox, 'name.txt')).readAsString(),
          completion(equals('contents')));
    });
  });

  expectTestPasses('file().create() overwrites an existing file', () {
    scheduleSandbox();

    d.file('name.txt', 'contents1').create();

    d.file('name.txt', 'contents2').create();

    schedule(() {
      expect(new File(path.join(sandbox, 'name.txt')).readAsString(),
          completion(equals('contents2')));
    });
  });

  expectTestPasses('file().validate() completes successfully if the filesystem '
      'matches the descriptor', () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('contents');
    });

    d.file('name.txt', 'contents').validate();
  });

  expectTestFailure("file().validate() fails if there's a file with the wrong "
      "contents", () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('wrongtents');
    });

    d.file('name.txt', 'contents').validate();
  }, (error) {
    expect(error.toString(), equals(
        "File 'name.txt' should contain:\n"
        "| contents\n"
        "but actually contained:\n"
        "X wrongtents"));
  });

  expectTestFailure("file().validate() fails if there's no file", () {
    scheduleSandbox();

    d.file('name.txt', 'contents').validate();
  }, (error) {
    expect(error.toString(),
        matches(r"^File not found: '[^']+[\\/]name\.txt'\.$"));
  });

  expectTestPasses("file().read() returns the contents of the file as a stream",
      () {
    expect(byteStreamToString(d.file('name.txt', 'contents').read()),
        completion(equals('contents')));
  });

  expectTestPasses("file().describe() returns the filename", () {
    expect(d.file('name.txt', 'contents').describe(), equals('name.txt'));
  });

  expectTestPasses('binaryFile().create() creates a file', () {
    scheduleSandbox();

    d.binaryFile('name.bin', [1, 2, 3, 4, 5]).create();

    schedule(() {
      expect(new File(path.join(sandbox, 'name.bin')).readAsBytes(),
          completion(equals([1, 2, 3, 4, 5])));
    });
  });

  expectTestPasses('binaryFile().validate() completes successfully if the '
      'filesystem matches the descriptor', () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.bin'))
          .writeAsBytes([1, 2, 3, 4, 5]);
    });

    d.binaryFile('name.bin', [1, 2, 3, 4, 5]).validate();
  });

  expectTestFailure("binaryFile().validate() fails if there's a file with the "
      "wrong contents", () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.bin'))
          .writeAsBytes([2, 4, 6, 8, 10]);
    });

    d.binaryFile('name.bin', [1, 2, 3, 4, 5]).validate();
  }, (error) {
    expect(error.toString(), equals(
        "File 'name.bin' didn't contain the expected binary data."));
  });

  expectTestPasses('matcherFile().create() creates an empty file', () {
    scheduleSandbox();

    d.matcherFile('name.txt', isNot(isEmpty)).create();

    schedule(() {
      expect(new File(path.join(sandbox, 'name.txt')).readAsString(),
          completion(equals('')));
    });
  });

  expectTestPasses('matcherFile().validate() completes successfully if the '
      'string contents of the file matches the matcher', () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('barfoobaz');
    });

    d.matcherFile('name.txt', contains('foo')).validate();
  });

  expectTestFailure("matcherFile().validate() fails if the string contents of "
      "the file doesn't match the matcher", () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('barfoobaz');
    });

    d.matcherFile('name.txt', contains('baaz')).validate();
  }, (error) {
    expect(error.toString(), equals(
        "Expected: contains 'baaz'\n"
        "  Actual: 'barfoobaz'\n"));
  });

  expectTestPasses('binaryMatcherFile().validate() completes successfully if '
      'the string contents of the file matches the matcher', () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('barfoobaz');
    });

    d.binaryMatcherFile('name.txt', contains(111)).validate();
  });

  expectTestFailure("binaryMatcherFile().validate() fails if the string "
      "contents of the file doesn't match the matcher", () {
    scheduleSandbox();

    schedule(() {
      return new File(path.join(sandbox, 'name.txt'))
          .writeAsString('barfoobaz');
    });

    d.binaryMatcherFile('name.txt', contains(12)).validate();
  }, (error) {
    expect(error.toString(), equals(
        "Expected: contains <12>\n"
        "  Actual: [98, 97, 114, 102, 111, 111, 98, 97, 122]\n"));
  });
}
