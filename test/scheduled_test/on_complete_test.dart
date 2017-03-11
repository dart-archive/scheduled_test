// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() {
  expectTestsPass('the onComplete queue is run if a test is successful', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      schedule(() => expect('foo', equals('foo')));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestsPass('the onComplete queue is run after an out-of-band callback',
      () {
    var outOfBandRun = false;
    test('test1', () {
      currentSchedule.onComplete.schedule(() {
        expect(outOfBandRun, isTrue);
      });

      pumpEventQueue().then(expectAsync1((_) {
        outOfBandRun = true;
      }));
    });
  });

  expectTestsPass('the onComplete queue is run after an out-of-band callback '
      'and waits for another out-of-band callback', () {
    var outOfBand1Run = false;
    var outOfBand2Run = false;
    test('test1', () {
      currentSchedule.onComplete.schedule(() {
        expect(outOfBand1Run, isTrue);

        pumpEventQueue().then(expectAsync1((_) {
          outOfBand2Run = true;
        }));
      });

      pumpEventQueue().then(expectAsync1((_) {
        outOfBand1Run = true;
      }));
    });

    test('test2', () => expect(outOfBand2Run, isTrue));
  });

  expectTestFailure('an out-of-band callback in the onComplete queue blocks '
      'the test', () {
    currentSchedule.onComplete.schedule(() {
      pumpEventQueue().then(expectAsync1((_) => throw 'error'));
    });
  }, (error) => expect(error, equals('error')));

  expectTestsPass('the onComplete queue is run after an asynchronous error',
      () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      schedule(() => expect('foo', equals('bar')));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onComplete queue is run after a synchronous error', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      throw 'error';
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('the onComplete queue is run after an out-of-band error', () {
    var onCompleteRun = false;
    test('test 1', () {
      currentSchedule.onComplete.schedule(() {
        onCompleteRun = true;
      });

      pumpEventQueue().then(expectAsync1((_) => expect('foo', equals('bar'))));
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  }, passing: ['test 2']);

  expectTestsPass('onComplete tasks can be scheduled during normal tasks', () {
    var onCompleteRun = false;
    test('test 1', () {
      schedule(() {
        currentSchedule.onComplete.schedule(() {
          onCompleteRun = true;
        });
      });
    });

    test('test 2', () {
      expect(onCompleteRun, isTrue);
    });
  });

  expectTestFailure('failures in onComplete cause test failures', () {
    currentSchedule.onComplete.schedule(() {
      expect('foo', equals('bar'));
    });
  }, (error) => expect(error, isTestFailure));
}
