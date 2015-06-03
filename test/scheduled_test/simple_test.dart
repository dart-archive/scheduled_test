// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestPasses('a scheduled test with a correct synchronous expectation '
      'should pass', () {
    expect('foo', equals('foo'));
  });

  expectTestFailure('a scheduled test with an incorrect synchronous '
      'expectation should fail', () {
    expect('foo', equals('bar'));
  }, (error) => expect(error, isTestFailure));

  expectTestPasses('a scheduled test with a correct asynchronous expectation '
      'should pass', () {
    expect(new Future.value('foo'), completion(equals('foo')));
  });

  expectTestFailure('a scheduled test with an incorrect asynchronous '
      'expectation should fail', () {
    expect(new Future.value('foo'), completion(equals('bar')));
  }, (error) => expect(error, isTestFailure));

  expectTestPasses('a passing scheduled synchronous expect should register',
      () {
    schedule(() => expect('foo', equals('foo')));
  });

  expectTestFailure('a failing scheduled synchronous expect should register',
      () => schedule(() => expect('foo', equals('bar'))),
      (error) => expect(error, isTestFailure));

  expectTestPasses('a passing scheduled asynchronous expect should '
      'register', () {
    schedule(() =>
        expect(new Future.value('foo'), completion(equals('foo'))));
  });

  expectTestFailure('a failing scheduled synchronous expect should '
      'register', () {
    schedule(() =>
        expect(new Future.value('foo'), completion(equals('bar'))));
  }, (error) => expect(error, isTestFailure));

  expectTestPasses('scheduled blocks should be run in order after the '
      'synchronous setup', () {
    var list = [1];
    schedule(() => list.add(2));
    list.add(3);
    schedule(() => expect(list, equals([1, 3, 4, 2])));
    list.add(4);
  });

  expectTestsPass('scheduled blocks should forward their return values as '
      'Futures', () {
    test('synchronous value', () {
      var future = schedule(() => 'value');
      expect(future, completion(equals('value')));
    });

    test('asynchronous value', () {
      var future = schedule(() => new Future.value('value'));
      expect(future, completion(equals('value')));
    });
  });

  expectTestPasses('scheduled blocks should wait for their Future return '
      'values to complete before proceeding', () {
    var value = 'unset';
    schedule(() => pumpEventQueue().then((_) {
      value = 'set';
    }));
    schedule(() => expect(value, equals('set')));
  });

  expectTestFailure('a test failure in a chained future in a scheduled block '
      'should be registered', () {
    schedule(() => new Future.value('foo')
        .then((v) => expect(v, equals('bar'))));
  }, (error) => expect(error, isTestFailure));

  expectTestFailure('an error in a chained future in a scheduled block should '
      'be registered', () {
    schedule(() => new Future.value().then((_) {
      throw 'error';
    }));
  }, (error) => expect(error, equals('error')));
}
