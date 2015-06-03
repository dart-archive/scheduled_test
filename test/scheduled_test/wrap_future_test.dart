// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestFailure('an out-of-band failure in wrapFuture is handled', () {
    mock_clock.mock().run();
    schedule(() {
      wrapFuture(sleep(1).then((_) => expect('foo', equals('bar'))));
    });
    schedule(() => sleep(2));
  }, (error) => expect(error, isTestFailure));

  expectTestFailure('an out-of-band failure in wrapFuture that finishes after '
      'the schedule is handled', () {
    mock_clock.mock().run();
    schedule(() {
      wrapFuture(sleep(2).then((_) => expect('foo', equals('bar'))));
    });
    schedule(() => sleep(1));
  }, (error) => expect(error, isTestFailure));

  expectTestPasses("wrapFuture should return the value of the wrapped future",
      () {
    schedule(() {
      expect(wrapFuture(pumpEventQueue().then((_) => 'foo')),
          completion(equals('foo')));
    });
  });

  expectTestPasses("a returned future should be implicitly wrapped",
      () {
    var futureComplete = false;
    currentSchedule.onComplete.schedule(() => expect(futureComplete, isTrue));

    return pumpEventQueue().then((_) => futureComplete = true);
  });

  expectTestPasses("a returned future should not block the schedule",
      () {
    var futureComplete = false;
    schedule(() => expect(futureComplete, isFalse));

    return pumpEventQueue().then((_) => futureComplete = true);
  });

  expectTestsPass("wrapFuture should pass through the error of the wrapped "
      "future", () {
    var error;
    test('test 1', () {
      schedule(() {
        wrapFuture(pumpEventQueue().then((_) {
          throw 'error';
        })).catchError(wrapAsync((e) {
          error = e;
        }));
      });
    });

    test('test 2', () {
      expect(error, equals('error'));
    });
  }, passing: ['test 2']);

  expectTestFailure("scheduled blocks whose return values are passed to "
      "wrapFuture should report exceptions once", () {
    wrapFuture(schedule(() {
      throw 'error';
    }));
  }, (error) => expect(error, equals('error')));
}
