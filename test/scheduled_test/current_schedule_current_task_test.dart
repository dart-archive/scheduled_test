// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() {
  expectTestPasses('currentSchedule.currentTask returns the current task while '
      'executing a task', () {
    schedule(() => expect('foo', equals('foo')), 'task 1');

    schedule(() {
      expect(currentSchedule.currentTask.description, equals('task 2'));
    }, 'task 2');

    schedule(() => expect('bar', equals('bar')), 'task 3');
  });

  expectTestPasses('currentSchedule.currentTask is null before the schedule '
      'has started', () {
    schedule(() => expect('foo', equals('foo')));

    expect(currentSchedule.currentTask, isNull);
  });

  expectTestPasses('currentSchedule.currentTask is null after the schedule has '
      'completed', () {
    schedule(() {
      expect(pumpEventQueue().then((_) {
        expect(currentSchedule.currentTask, isNull);
      }), completes);
    });

    schedule(() => expect('foo', equals('foo')));
  });

  expectTestPasses('currentSchedule.currentQueue returns the current queue '
      'while executing a task', () {
    schedule(() {
      expect(currentSchedule.currentQueue.name, equals('tasks'));
    });
  });

  expectTestPasses('currentSchedule.currentQueue is tasks before the schedule '
      'has started', () {
    schedule(() => expect('foo', equals('foo')));

    expect(currentSchedule.currentQueue.name, equals('tasks'));
  });
}
