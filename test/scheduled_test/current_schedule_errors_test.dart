// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

void main() {
  setUpMockClock();

  expectTestFailure('currentSchedule.errors contains the error in the '
      'onComplete queue', () {
    throw 'error';
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'registerException synchronously', () {
    registerException('error');
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'registerException asynchronously', () {
    schedule(() => registerException('error'));
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains an error passed into '
      'registerException out-of-band', () {
    pumpEventQueue().then(expectAsync1((_) => registerException('error')));
  }, (error) => expect(error, equals('error')));

  expectTestFailure('currentSchedule.errors contains only the first '
      'out-of-band error from the main task queue in onComplete', () {
    mockClock.run();

    sleep(1).then(expectAsync1((_) {
      throw 'error1';
    }));
    sleep(2).then(expectAsync1((_) {
      throw 'error2';
    }));
  }, (error) => expect(error, equals('error1')));
}
