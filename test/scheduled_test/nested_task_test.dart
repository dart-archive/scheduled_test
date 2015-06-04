// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() {
  setUpMockClock();

  expectTestPasses("nested schedule() runs its function immediately (but "
      "asynchronously)", () {
    schedule(() {
      var nestedScheduleRun = false;
      schedule(() {
        nestedScheduleRun = true;
      });

      expect(nestedScheduleRun, isFalse);
      expect(pumpEventQueue().then((_) => nestedScheduleRun),
          completion(isTrue));
    });
  });

  expectTestPasses("nested schedule() calls don't wait for one another", () {
    mockClock.run();
    var sleepFinished = false;
    schedule(() {
      schedule(() => sleep(1).then((_) {
        sleepFinished = true;
      }));
      schedule(() => expect(sleepFinished, isFalse));
    });
  });

  expectTestPasses("nested schedule() calls block their parent task", () {
    mockClock.run();
    var sleepFinished = false;
    schedule(() {
      schedule(() => sleep(1).then((_) {
        sleepFinished = true;
      }));
    });

    schedule(() => expect(sleepFinished, isTrue));
  });

  expectTestPasses("nested schedule() calls forward their Future values", () {
    mockClock.run();
    schedule(() {
      expect(schedule(() => 'foo'), completion(equals('foo')));
    });
  });

  expectTestFailure("errors in nested schedule() calls are properly registered",
      () {
    schedule(() {
      schedule(() {
        throw 'error';
      });
    });
  }, (error) => expect(error, equals('error')));

  expectTestFailure("nested scheduled blocks whose return values are passed to "
      "expect(..., completes) should report exceptions once", () {
    schedule(() {
      expect(schedule(() {
        throw 'error';
      }), completes);

      return pumpEventQueue();
    });
  }, (error) => expect(error, equals('error')));
}
