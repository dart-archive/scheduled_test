// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_utils;

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/utils.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'package:metatest/metatest.dart';

export 'package:scheduled_test/src/utils.dart';

/// A matcher that validates whether an object is a [TestFailure].
final isTestFailure = new isInstanceOf<TestFailure>();

/// Returns a [Future] that will complete in [milliseconds].
Future sleep(int milliseconds) {
  var completer = new Completer();
  mock_clock.newTimer(new Duration(milliseconds: milliseconds), () {
    completer.complete();
  });
  return completer.future;
}

/// Creates a metatest with [body] and asserts that it passes.
///
/// This is like [expectTestsPass], but the [test] is set up automatically.
void expectTestPasses(String description, body()) =>
  expectTestsPass(description, () => test('test', body));

/// Creates a metatest that runs [testBody], captures its schedule errors, and
/// passes them to [validator].
///
/// [testBody] is expected to produce an error, while [validator] is expected to
/// produce none.
void expectTestFails(String description, Future testBody(),
    void validator(List<ScheduleError> errors)) {
  expectTestsPass(description, () {
    var errors;
    test('test body', () {
      currentSchedule.onComplete.schedule(() {
        errors = currentSchedule.errors;
      });

      testBody();
    });

    test('validate errors', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      validator(errors);
    });
  }, passing: ['validate errors']);
}

/// Like [expectTestFails], but expects there to be only a single error and
/// unwraps that error before passing it to [validator].
void expectTestFailure(String description, Future testBody(),
    void validator(error))  {
  expectTestFails(description, testBody, (errors) {
    expect(errors, hasLength(1));
    validator(errors.single.error);
  });
}
