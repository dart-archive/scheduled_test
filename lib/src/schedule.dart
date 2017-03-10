// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

// TODO(nweiz): Stop importing from src when dart-lang/test#48 is fixed.
import 'package:test/src/backend/invoker.dart';
import 'package:test/test.dart' as test;

import 'schedule_error.dart';
import 'task.dart';
import 'utils.dart';

/// The schedule of tasks to run for a single test.
///
/// This has two task queues: [tasks] and [onComplete]. It also provides
/// visibility into the current state of the schedule.
class Schedule<T> {
  /// The main task queue for the schedule. These tasks are run before the other
  /// queues and generally constitute the main test body.
  TaskQueue<T> get tasks => _tasks;
  TaskQueue<T> _tasks;

  /// The queue of tasks to run after [tasks] has run. This queue will run
  /// whether or not an error occurred. If one did, it will be available in
  /// [errors]. Note that expectation failures count as errors.
  ///
  /// If an error occurs in a task in this queue, all further tasks will be
  /// skipped.
  TaskQueue<T> get onComplete => _onComplete;
  TaskQueue<T> _onComplete;

  /// Returns the [Task] that's currently executing, or `null` if there is no
  /// such task. This will be `null` both before the schedule starts running and
  /// after it's finished.
  Task<T> get currentTask => _currentTask;
  Task<T> _currentTask;

  /// The current state of the schedule.
  ScheduleState get state => _state;
  ScheduleState _state = ScheduleState.SET_UP;

  /// Errors thrown by the task queues.
  ///
  /// When running tasks in [tasks], this will always be empty. If an error
  /// occurs in [tasks], it will be added to this list. Errors thrown during
  /// [onComplete] will also be added to this list, although no scheduled tasks
  /// will be run afterwards.
  ///
  /// Any out-of-band callbacks that throw errors will also have those errors
  /// added to this list.
  List<ScheduleError> get errors =>
      new UnmodifiableListView<ScheduleError>(_errors);
  final _errors = <ScheduleError>[];

  /// Additional debugging info registered via [addDebugInfo].
  List<String> get debugInfo => new UnmodifiableListView<String>(_debugInfo);
  final _debugInfo = <String>[];

  /// The task queue that's currently being run.
  ///
  /// One of [tasks] or [onComplete]. This starts as [tasks], and can only be
  /// `null` after the schedule is done.
  TaskQueue<T> get currentQueue =>
    _state == ScheduleState.DONE ? null : _currentQueue;
  TaskQueue<T> _currentQueue;

  /// Creates a new schedule with empty task queues.
  Schedule() {
    _tasks = new TaskQueue<T>._("tasks", this);
    _onComplete = new TaskQueue<T>._("onComplete", this);
    _currentQueue = _tasks;
  }

  /// Sets up this schedule by running [setUp], then runs all the task queues in
  /// order.
  Future run(void setUp()) {
    return Invoker.current.waitForOutstandingCallbacks(() {
      return runZoned(() {
        try {
          setUp();
        } catch (_) {
          // Even though the scheduling failed, we need to run the onComplete
          // queue, so we set the schedule state to RUNNING.
          _state = ScheduleState.RUNNING;
          rethrow;
        }

        _state = ScheduleState.RUNNING;
        return tasks._run();
      }, onError: _handleError);
    }).then((_) {
      return Invoker.current.waitForOutstandingCallbacks(() {
        return runZoned(onComplete._run, onError: _handleError);
      });
    }).then((_) {
      _state = ScheduleState.DONE;
    });
  }

  /// Stop the current [TaskQueue] after the current task and any out-of-band
  /// tasks stop executing. If this is called before [this] has started running,
  /// no tasks in the [tasks] queue will be run.
  ///
  /// This won't cause an error, but any errors that are otherwise signaled will
  /// still cause the test to fail.
  void abort() {
    if (_state == ScheduleState.DONE) {
      throw new StateError("Called abort() after the schedule has finished "
          "running.");
    }

    currentQueue._abort();
  }

  void _handleError(error, [StackTrace stackTrace]) {
    if (state == ScheduleState.DONE) {
      // If the schedule has finished, pass the error upward so the caller can
      // display it how it wants. There's nothing useful we can add by wrapping
      // it in a ScheduleError anyway.
      Zone.current.handleUncaughtError(error, stackTrace);
    } else {
      // If the schedule is setting up running, stop it and record this error.
      var scheduleError = new ScheduleError.from(
          this, error, stackTrace: stackTrace);
      if (!_errors.contains(scheduleError)) _errors.add(scheduleError);
      _currentQueue._abort();
      Invoker.current.removeAllOutstandingCallbacks();
    }
  }

  /// Adds [info] to the debugging output that will be printed if the test
  /// fails.
  ///
  /// This won't cause the test to fail, nor will it short-circuit the current
  /// [TaskQueue]; it's just useful for providing additional information that
  /// may not fit cleanly into an existing error.
  void addDebugInfo(String info) => _debugInfo.add(info);

  /// Returns a string representation of all errors registered on this schedule.
  String errorString() {
    if (errors.isEmpty) return "The schedule had no errors.";
    if (errors.length == 1 && debugInfo.isEmpty) return errors.first.toString();

    var border = "\n==========================================================="
      "=====================\n";
    var errorStrings = errors.map((e) => e.toString()).join(border);
    var message = "The schedule had ${errors.length} errors:\n$errorStrings";

    if (!debugInfo.isEmpty) {
      message = "$message$border\nDebug info:\n${debugInfo.join(border)}";
    }

    return message;
  }
}

/// An enum of states for a [Schedule].
class ScheduleState {
  /// The schedule can have tasks added to its queue, but is not yet running
  /// them.
  static const SET_UP = const ScheduleState._("SET_UP");

  /// The schedule is actively running tasks. This includes running tasks in
  /// [Schedule.onComplete].
  static const RUNNING = const ScheduleState._("RUNNING");

  /// The schedule has finished running all its tasks, either successfully or
  /// with an error.
  static const DONE = const ScheduleState._("DONE");

  /// The name of the state.
  final String name;

  const ScheduleState._(this.name);

  String toString() => name;
}

/// A queue of asynchronous tasks to execute in order.
class TaskQueue<T> {
  /// The tasks in the queue.
  List<Task<T>> get contents => new UnmodifiableListView<Task<T>>(_contents);
  final _contents = new Queue<Task<T>>();

  /// The name of the queue, for debugging purposes.
  final String name;

  /// The [Schedule] that created this queue.
  final Schedule<T> _schedule;

  /// Whether to stop running after the current task.
  bool _aborted = false;

  TaskQueue._(this.name, this._schedule);

  /// Whether this queue is currently running.
  bool get isRunning => _schedule.state == ScheduleState.RUNNING &&
      _schedule.currentQueue == this;

  /// Whether this queue is running its tasks (as opposed to waiting for
  /// out-of-band callbacks or not running at all).
  bool get isRunningTasks => isRunning && _schedule.currentTask != null;

  /// Schedules a task, [fn], to run asynchronously as part of this queue. Tasks
  /// will be run in the order they're scheduled. In [fn] returns a [Future],
  /// tasks after it won't be run until that [Future] completes.
  ///
  /// The return value will be completed once the scheduled task has finished
  /// running. Its return value is the same as the return value of [fn], or the
  /// value it completes to if it's a [Future].
  ///
  /// If [description] is passed, it's used to describe the task for debugging
  /// purposes when an error occurs.
  ///
  /// If this is called when this queue is currently running, it will run [fn]
  /// on the next event loop iteration rather than adding it to a queue--this is
  /// known as a "nested task". The current task will not complete until [fn]
  /// (and any [Future] it returns) has finished running. Nested tasks run in
  /// parallel, unlike top-level tasks which run in sequence.
  Future<T> schedule(T fn(), [String description]) {
    if (isRunning) {
      var task = _schedule.currentTask;
      TaskBody<T> wrappedFn = () {
        var whenDone = test.expectAsync0(() {});
        return new Future.value().then((_) => fn()).then((result) {
          whenDone();
          return result;
        });
      };
      if (task == null) return wrappedFn();
      return task.runChild(wrappedFn, description);
    }

    var task = new Task<T>(fn, description, this);
    _contents.add(task);
    return task.result;
  }

  /// Runs all the tasks in this queue in order.
  Future _run() {
    _schedule._currentQueue = this;
    Invoker.current.heartbeat();
    return Future.forEach(_contents, (task) {
      _schedule._currentTask = task;
      if (_aborted) return null;

      return task.fn().then((_) {
        Invoker.current.heartbeat();
      }).catchError((error, stackTrace) {
        _schedule._handleError(error, stackTrace);
      });
    }).then((_) {
      _schedule._currentTask = null;
    });
  }

  /// Stops this queue after the current task and any out-of-band callbacks
  /// finish running.
  void _abort() {
    assert(_schedule.state == ScheduleState.SET_UP || isRunning);
    _aborted = true;
  }

  String toString() => name;

  /// Returns a detailed representation of the queue as a tree of tasks. If
  /// [highlight] is passed, that task is specially highlighted.
  ///
  /// [highlight] must be a task in this queue.
  String generateTree([Task highlight]) {
    assert(highlight == null || highlight.queue == this);
    return _contents.map((task) {
      var taskString = task == highlight
          ? task.toStringWithStackTrace()
          : task.toString();
      taskString = prefixLines(taskString,
          firstPrefix: task == highlight ? "> " : "* ");

      if (task == highlight && !task.children.isEmpty) {
        var childrenString = task.children.map((child) {
          var prefix = ">";
          if (child.state == TaskState.ERROR) {
            prefix = "X";
          } else if (child.state == TaskState.SUCCESS) {
            prefix = "*";
          }

          var childString = prefix == "*"
              ? child.toString()
              : child.toStringWithStackTrace();
          return prefixLines(childString,
              firstPrefix: "  $prefix ", prefix: "  | ");
        }).join('\n');
        taskString = '$taskString\n$childrenString';
      }

      return taskString;
    }).join("\n");
  }
}
