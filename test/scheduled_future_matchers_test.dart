// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestPasses("expect(..., completes) with a completing future should "
      "pass", () {
    expect(pumpEventQueue(), completes);
  });

  expectTestFailure("expect(..., completes) with a failing future should "
      "signal an out-of-band error", () {
    expect(pumpEventQueue().then((_) => throw 'error'), completes);
  }, (error) => expect(error, equals('error')));

  expectTestPasses("expect(..., completion(...)) with a matching future should "
      "pass", () {
    expect(pumpEventQueue().then((_) => 'foo'), completion(equals('foo')));
  });

  expectTestFailure("expect(..., completion(...)) with a non-matching future "
      "should signal an out-of-band error", () {
    expect(pumpEventQueue().then((_) => 'foo'), completion(equals('bar')));
  }, (error) => expect(error, isTestFailure));

  expectTestFailure("expect(..., completion(...)) with a failing future should "
      "signal an out-of-band error", () {
    expect(pumpEventQueue().then((_) {
      throw 'error';
    }), completion(equals('bar')));
  }, (error) => expect(error, equals('error')));
}
