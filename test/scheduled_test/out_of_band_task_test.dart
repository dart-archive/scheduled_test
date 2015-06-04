// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../utils.dart';

void main() {
  setUpMockClock();

  expectTestPasses("out-of-band schedule() runs its function immediately (but "
      "asynchronously)", () {
    mockClock.run();
    schedule(() {
      expect(sleep(1).then((_) {
        var nestedScheduleRun = false;
        schedule(() {
          nestedScheduleRun = true;
        });

        expect(nestedScheduleRun, isFalse);
        expect(pumpEventQueue().then((_) => nestedScheduleRun),
            completion(isTrue));
      }), completes);
    });
  });

  expectTestPasses("out-of-band schedule() calls block their parent queue", () {
    mockClock.run();
    var scheduleRun = false;
    expect(sleep(1).then((_) {
      schedule(() => sleep(1).then((_) {
        scheduleRun = true;
      }));
    }), completes);

    currentSchedule.onComplete.schedule(() => expect(scheduleRun, isTrue));
  });
}
