// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() {
  expectTestPasses("aborting the schedule before it's started running should "
      "cause no tasks to be run", () {
    schedule(() {
      throw 'error';
    });

    currentSchedule.abort();
  });

  expectTestPasses("aborting the schedule while it's running should stop "
      "future tasks from running", () {
    schedule(currentSchedule.abort);

    schedule(() {
      throw 'error';
    });
  });

  expectTestsPass("aborting the schedule while it's running shouldn't stop "
      "tasks in other queues from running", () {
    var onCompleteRun = false;
    test('test 1', () {
      schedule(currentSchedule.abort);

      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestPasses("aborting the schedule in a non-tasks queue should stop "
      "future tasks from running", () {
    currentSchedule.onComplete.schedule(() {
      currentSchedule.abort();
    });

    currentSchedule.onComplete.schedule(() {
      throw 'error';
    });
  });

  expectTestFailure("aborting the schedule after an out-of-band error should "
      "still surface the error", () {
    schedule(() {
      registerException('error');
      currentSchedule.abort();
    });
  }, (error) => expect(error, equals('error')));
}
