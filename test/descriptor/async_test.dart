// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:metatest/metatest.dart';
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'utils.dart';

void main() {
  expectTestPasses("async().create() forwards to file().create", () {
    scheduleSandbox();

    d.async(pumpEventQueue().then((_) {
      return d.file('name.txt', 'contents');
    })).create();

    d.file('name.txt', 'contents').validate();
  });

  expectTestPasses("async().create() forwards to directory().create", () {
    scheduleSandbox();

    d.async(pumpEventQueue().then((_) {
      return d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]);
    })).create();

    d.dir('dir', [
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  });

  expectTestPasses("async().validate() forwards to file().validate", () {
    scheduleSandbox();

    d.file('name.txt', 'contents').create();

    d.async(pumpEventQueue().then((_) {
      return d.file('name.txt', 'contents');
    })).validate();
  });

  expectTestFailure("async().validate() fails if file().validate fails", () {
    scheduleSandbox();

    d.async(pumpEventQueue().then((_) {
      return d.file('name.txt', 'contents');
    })).validate();
  }, (error) {
    expect(error.toString(),
           matches(r"^File not found: '[^']+[\\/]name\.txt'\.$"));
  });

  expectTestPasses("async().validate() forwards to directory().validate", () {
    scheduleSandbox();

    d.dir('dir', [
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).create();

    d.async(pumpEventQueue().then((_) {
      return d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]);
    })).validate();
  });

  expectTestFailure("async().create() fails if directory().create fails", () {
    scheduleSandbox();

    d.async(pumpEventQueue().then((_) {
      return d.dir('dir', [
        d.file('file1.txt', 'contents1'),
        d.file('file2.txt', 'contents2')
      ]);
    })).validate();
  }, (error) {
    expect(error.toString(),
        matches(r"^Directory not found: '[^']+[\\/]dir'\.$"));
  });
}
