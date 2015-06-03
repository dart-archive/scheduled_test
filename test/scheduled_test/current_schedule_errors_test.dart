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

  expectTestResults('a scheduled test with an out-of-band error should fail',
      () {
    mock_clock.mock().run();
    test('test 1', () {
      sleep(1).then((_) => throw 'error');
    });

    test('test 2', () {
      return sleep(2);
    });
  }, [{
    'description': 'test 1',
    'result': 'error'
  }, {
    'description': 'test 2',
    'result': 'pass'
  }]);

  expectTestFailure('currentSchedule.errors contains the error in the '
      'onComplete queue', () {
    throw 'error';
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'signalError synchronously', () {
    currentSchedule.signalError('error');
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'signalError asynchronously', () {
    schedule(() => currentSchedule.signalError('error'));
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'signalError out-of-band', () {
    pumpEventQueue().then(wrapAsync((_) {
      return currentSchedule.signalError('error');
    }));
  }, (error) => expect(error, equals('error')));

  expectTestFails('currentSchedule.errors contains multiple out-of-band errors '
      'from the main task queue in onComplete', () {
    mock_clock.mock().run();

    sleep(1).then(wrapAsync((_) {
      throw 'error1';
    }));
    sleep(2).then(wrapAsync((_) {
      throw 'error2';
    }));
  }, (errors) {
    expect(errors.map((e) => e.error), equals(['error1', 'error2']));
  });

  expectTestFails('currentSchedule.errors contains multiple out-of-band errors '
      'from the main task queue in onComplete reported via wrapFuture', () {
    mock_clock.mock().run();

    wrapFuture(sleep(1).then((_) {
      throw 'error1';
    }));
    wrapFuture(sleep(2).then((_) {
      throw 'error2';
    }));
  }, (errors) {
    expect(errors.map((e) => e.error), equals(['error1', 'error2']));
  });

  expectTestFails('currentSchedule.errors contains both an out-of-band error '
      'and an error raised afterwards in a task', () {
    mock_clock.mock().run();

    sleep(1).then(wrapAsync((_) {
      throw 'out-of-band';
    }));

    schedule(() => sleep(2).then((_) {
      throw 'in-band';
    }));
  }, (errors) {
    expect(errors.map((e) => e.error), equals(['out-of-band', 'in-band']));
  });

  expectTestFails('currentSchedule.errors contains both an error raised in a '
      'task and an error raised afterwards out-of-band', () {
    mock_clock.mock().run();

    sleep(2).then(wrapAsync((_) {
      throw 'out-of-band';
    }));

    schedule(() => sleep(1).then((_) {
      throw 'in-band';
    }));
  }, (errors) {
    expect(errors.map((e) => e.error), equals(['in-band', 'out-of-band']));
  });
}
