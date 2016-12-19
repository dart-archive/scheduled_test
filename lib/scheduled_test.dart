// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(nweiz): Add support for calling [schedule] while the schedule is already
// running.
// TODO(nweiz): Port the non-Pub-specific scheduled test libraries from Pub.
import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart' as test_pkg;

import 'src/schedule.dart';

export 'package:test/test.dart'
    hide test, group, setUp, tearDown, setUpAll, tearDownAll;

export 'src/schedule.dart';
export 'src/schedule_error.dart';
export 'src/task.dart';

typedef void _NonaryFunction();

/// The [Schedule] for the current test. This is used to add new tasks and
/// inspect the state of the schedule.
///
/// This is `null` when there's no test currently running.
Schedule get currentSchedule => _currentSchedule;
Schedule _currentSchedule;

/// The user-provided set-up function for the currently-running test.
///
/// This is set for each test during [test_pkg.setUp].
_NonaryFunction _setUpFn;

/// The user-provided tear-down function for the currently-running test.
///
/// This is set for each test during [test_pkg.setUp].
_NonaryFunction _tearDownFn;

/// The user-provided set-up function for the current test scope.
final _setUpForGroup = new _DeclarerProperty<_NonaryFunction>();

/// The user-provided tear-down function for the current test scope.
final _tearDownForGroup = new _DeclarerProperty<_NonaryFunction>();

/// Whether [_initializeForGroup] has been called in this group scope.
final _initializedForGroup = new _DeclarerProperty<bool>(false);

/// Whether or not the tests currently being defined are in a group.
///
/// This is only true when defining tests, not when executing them.
final _inGroup = new _DeclarerProperty<bool>(false);

/// Creates a new test case with the given description and body.
///
/// This has the same semantics as [test_pkg.test].
void test(String description, body(), {String testOn, test_pkg.Timeout timeout,
    skip, tags, Map<String, dynamic> onPlatform}) {
  maybeWrapFuture(future) {
    if (future != null) test_pkg.expect(future, test_pkg.completes);
  }

  _initializeForGroup();
  test_pkg.test(description, () {
    _currentSchedule = new Schedule();
    return currentSchedule.run(() {
      if (_setUpFn != null) maybeWrapFuture(_setUpFn());
      maybeWrapFuture(body());
      if (_tearDownFn != null) maybeWrapFuture(_tearDownFn());
    }).then((_) {
      if (currentSchedule.errors.isEmpty) return;
      // Pass an empty trace so that the test package doesn't try to construct
      // its own useless stack trace. All the trace information we need is in
      // the schedule's error string.
      test_pkg.registerException(currentSchedule.errorString(), new Trace([]));
    });
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform);
}

/// Creates a new named group of tests. This has the same semantics as
/// [test_pkg.group].
void group(String description, void body(), {String testOn,
    test_pkg.Timeout timeout, skip, tags, Map<String, dynamic> onPlatform}) {
  _initializeForGroup();
  test_pkg.group(description, () {
    var oldSetUp = _setUpForGroup.value;
    var oldTearDown = _tearDownForGroup.value;
    var wasInitializedForGroup = _initializedForGroup.value;
    var wasInGroup = _inGroup.value;
    _setUpForGroup.value = null;
    _tearDownForGroup.value = null;
    _initializedForGroup.value = false;
    _inGroup.value = true;
    body();
    _setUpForGroup.value = oldSetUp;
    _tearDownForGroup.value = oldTearDown;
    _initializedForGroup.value = wasInitializedForGroup;
    _inGroup.value = wasInGroup;
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform);
}

/// Registers a function to be run once before all tests.
///
/// This has the same semantics as [test_pkg.setUpAll].
void setUpAll(body()) {
  maybeWrapFuture(future) {
    if (future != null) test_pkg.expect(future, test_pkg.completes);
  }

  test_pkg.setUpAll(() {
    _currentSchedule = new Schedule();
    return currentSchedule.run(() {
      maybeWrapFuture(body());
    }).then((_) {
      if (currentSchedule.errors.isEmpty) return;
      // Pass an empty trace so that the test package doesn't try to construct
      // its own useless stack trace. All the trace information we need is in
      // the schedule's error string.
      test_pkg.registerException(currentSchedule.errorString(), new Trace([]));
    }).whenComplete(() {
      _currentSchedule = null;
    });
  });
}

/// Registers a function to be run once after all tests.
///
/// This has the same semantics as [test_pkg.tearDownAll].
void tearDownAll(body()) {
  maybeWrapFuture(future) {
    if (future != null) test_pkg.expect(future, test_pkg.completes);
  }

  test_pkg.tearDownAll(() {
    _currentSchedule = new Schedule();
    return currentSchedule.run(() {
      maybeWrapFuture(body());
    }).then((_) {
      if (currentSchedule.errors.isEmpty) return;
      // Pass an empty trace so that the test package doesn't try to construct
      // its own useless stack trace. All the trace information we need is in
      // the schedule's error string.
      test_pkg.registerException(currentSchedule.errorString(), new Trace([]));
    }).whenComplete(() {
      _currentSchedule = null;
    });
  });
}

/// Schedules a task, [fn], to run asynchronously as part of the main task queue
/// of [currentSchedule]. Tasks will be run in the order they're scheduled. If
/// [fn] returns a [Future], tasks after it won't be run until that [Future]
/// completes.
///
/// The return value will be completed once the scheduled task has finished
/// running. Its return value is the same as the return value of [fn], or the
/// value it completes to if it's a [Future].
///
/// If [description] is passed, it's used to describe the task for debugging
/// purposes when an error occurs.
///
/// If this is called when a task queue is currently running, it will run [fn]
/// on the next event loop iteration rather than adding it to a queue. The
/// current task will not complete until [fn] (and any [Future] it returns) has
/// finished running.
Future/*<T>*/ schedule/*<T>*/(/*=T*/ fn(), [String description]) =>
  currentSchedule.tasks.schedule(fn, description);

/// Register a [setUp] function for a test [group].
///
/// This has the same semantics as [test_pkg.setUp]. Tasks may be scheduled
/// using [schedule] within [setUpFn], and [currentSchedule] may be accessed as
/// well.
void setUp(setUpFn()) {
  _setUpForGroup.value = setUpFn;
}

/// Register a [tearDown] function for a test [group].
///
/// This has the same semantics as [test_pkg.tearDown]. Tasks may be scheduled
/// using [schedule] within [tearDownFn], and [currentSchedule] may be accessed
/// as well. Note that [tearDownFn] will be run synchronously after the test
/// body finishes running, which means it will run before any scheduled tasks
/// have begun.
///
/// To run code after the schedule has finished running, use
/// `currentSchedule.onComplete.schedule`.
void tearDown(tearDownFn()) {
  _tearDownForGroup.value = tearDownFn;
}

/// Registers callbacks for [test_pkg.setUp] and [test_pkg.tearDown] that set up
/// and tear down the scheduled test infrastructure and run the user's [setUp]
/// and [tearDown] callbacks.
void _initializeForGroup() {
  if (_initializedForGroup.value) return;
  _initializedForGroup.value = true;

  var setUpFn = _setUpForGroup.value;
  var tearDownFn = _tearDownForGroup.value;

  if (_inGroup.value) {
    test_pkg.setUp(() => _addSetUpTearDown(setUpFn, tearDownFn));
    return;
  }

  test_pkg.setUp(() {
    if (currentSchedule != null) {
      throw new StateError('There seems to be another scheduled test '
          'still running.');
    }

    _addSetUpTearDown(setUpFn, tearDownFn);
  });

  test_pkg.tearDown(() {
    _currentSchedule = null;
    _setUpFn = null;
    _tearDownFn = null;
  });
}

/// Set [_setUpFn] and [_tearDownFn] appropriately.
void _addSetUpTearDown(void setUpFn(), void tearDownFn()) {
  if (setUpFn != null) {
    if (_setUpFn != null) {
      var parentFn = _setUpFn;
      _setUpFn = () { parentFn(); setUpFn(); };
    } else {
      _setUpFn = setUpFn;
    }
  }

  if (tearDownFn != null) {
    if (_tearDownFn != null) {
      var parentFn = _tearDownFn;
      _tearDownFn = () { parentFn(); tearDownFn(); };
    } else {
      _tearDownFn = tearDownFn;
    }
  }
}

/// A property attached to the test runner's current declarer.
///
/// This is used to scope otherwise-global fields so that multiple instances of
/// scheduled test can coexist in the same isolate, albeit not at the same time.
class _DeclarerProperty<T> {
  /// The expando used to attach the property to the declarers.
  final _expando = new Expando<T>();

  /// The default value, if any.
  final T _defaultValue;

  /// The object to associate with the property.
  ///
  /// This will usually be a declarer, but if there is no declarer this will be
  /// an Expando-safe value that's used to fall back to global properties.
  Object get _declarer {
    var declarer = Zone.current[#test.declarer];
    if (declarer == null) return #declarer;
    return declarer;
  }

  // TODO(nweiz): Use the test API to get the declarer when dart-lang/test#48 is
  // fixed.
  /// Returns the value of the property.
  T get value {
    var value = _expando[_declarer];
    return value == null ? _defaultValue : value;
  }

  /// Sets the value of the property.
  set value(T value) {
    _expando[_declarer] = value;
  }

  /// Creates a new property.
  ///
  /// If [defaultValue] is passed, it's the default for when the property is
  /// unset.
  _DeclarerProperty([this._defaultValue]);
}
