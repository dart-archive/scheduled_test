// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/descriptor.dart' as d;
import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() {
  expectTestPasses("directory().create() creates a directory and its contents",
      () {
    scheduleSandbox();

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).create();

    schedule(() {
      expect(new File(path.join(sandbox, 'dir', 'file1.txt')).readAsString(),
          completion(equals('contents1')));
      expect(new File(path.join(sandbox, 'dir', 'file2.txt')).readAsString(),
          completion(equals('contents2')));
      expect(new File(path.join(sandbox, 'dir', 'subdir', 'subfile1.txt'))
              .readAsString(),
          completion(equals('subcontents1')));
      expect(new File(path.join(sandbox, 'dir', 'subdir', 'subfile2.txt'))
              .readAsString(),
          completion(equals('subcontents2')));
    });
  });

  expectTestPasses("directory().create() works if the directory already exists",
      () {
    scheduleSandbox();

    d.dir('dir').create();
    d.dir('dir', [d.file('name.txt', 'contents')]).create();

    schedule(() {
      expect(new File(path.join(sandbox, 'dir', 'name.txt')).readAsString(),
          completion(equals('contents')));
    });
  });

  expectTestPasses("directory().validate() completes successfully if the "
      "filesystem matches the descriptor", () {
    scheduleSandbox();

    schedule(() {
      var dirPath = path.join(sandbox, 'dir');
      var subdirPath = path.join(dirPath, 'subdir');
      return new Directory(subdirPath).create(recursive: true).then((_) {
        return Future.wait([
          new File(path.join(dirPath, 'file1.txt'))
              .writeAsString('contents1'),
          new File(path.join(dirPath, 'file2.txt'))
              .writeAsString('contents2'),
          new File(path.join(subdirPath, 'subfile1.txt'))
              .writeAsString('subcontents1'),
          new File(path.join(subdirPath, 'subfile2.txt'))
              .writeAsString('subcontents2')
        ]);
      });
    });

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  });

  expectTestFailure("directory().validate() fails if a directory isn't found",
      () {
    scheduleSandbox();

    schedule(() {
      var dirPath = path.join(sandbox, 'dir');
      return new Directory(dirPath).create().then((_) {
        return Future.wait([
          new File(path.join(dirPath, 'file1.txt'))
              .writeAsString('contents1'),
          new File(path.join(dirPath, 'file2.txt'))
              .writeAsString('contents2')
        ]);
      });
    });

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  }, (error) {
    expect(error.toString(),
        matches(r"^Directory not found: '[^']+[\\/]dir[\\/]subdir'\.$"));
  });

  expectTestFailure("directory().validate() fails if a file isn't found", () {
    scheduleSandbox();

    schedule(() {
      var dirPath = path.join(sandbox, 'dir');
      var subdirPath = path.join(dirPath, 'subdir');
      return new Directory(subdirPath).create(recursive: true).then((_) {
        return Future.wait([
          new File(path.join(dirPath, 'file1.txt'))
              .writeAsString('contents1'),
          new File(path.join(subdirPath, 'subfile1.txt'))
              .writeAsString('subcontents1'),
          new File(path.join(subdirPath, 'subfile2.txt'))
              .writeAsString('subcontents2')
        ]);
      });
    });

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  }, (error) {
    expect(error.toString(),
        matches(r"^File not found: '[^']+[\\/]dir[\\/]file2\.txt'\.$"));
  });

  expectTestFailure("directory().validate() fails if multiple children aren't "
      "found or have the wrong contents", () {
    scheduleSandbox();

    schedule(() {
      var dirPath = path.join(sandbox, 'dir');
      var subdirPath = path.join(dirPath, 'subdir');
      return new Directory(subdirPath).create(recursive: true).then((_) {
        return Future.wait([
          new File(path.join(dirPath, 'file1.txt'))
              .writeAsString('contents1'),
          new File(path.join(subdirPath, 'subfile2.txt'))
              .writeAsString('subwrongtents2')
        ]);
      });
    });

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  }, (error) {
    expect(error.toString(), matches(
        r"^\* File not found: '[^']+[\\/]dir[\\/]subdir[\\/]subfile1\.txt'\."
            r"\n"
        r"\* File 'subfile2\.txt' should contain:\n"
        r"  \| subcontents2\n"
        r"  but actually contained:\n"
        r"  X subwrongtents2\n"
        r"\* File not found: '[^']+[\\/]dir[\\/]file2\.txt'\.$"));
  });

  expectTestFailure("directory().validate() fails if a file has the wrong "
      "contents", () {
    scheduleSandbox();

    schedule(() {
      var dirPath = path.join(sandbox, 'dir');
      var subdirPath = path.join(dirPath, 'subdir');
      return new Directory(subdirPath).create(recursive: true).then((_) {
        return Future.wait([
          new File(path.join(dirPath, 'file1.txt'))
              .writeAsString('contents1'),
          new File(path.join(dirPath, 'file2.txt'))
              .writeAsString('contents2'),
          new File(path.join(subdirPath, 'subfile1.txt'))
              .writeAsString('wrongtents1'),
          new File(path.join(subdirPath, 'subfile2.txt'))
              .writeAsString('subcontents2')
        ]);
      });
    });

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).validate();
  }, (error) {
    expect(error.toString(), equals(
        "File 'subfile1.txt' should contain:\n"
        "| subcontents1\n"
        "but actually contained:\n"
        "X wrongtents1"));
  });

  expectTestPasses("directory().load() loads a file", () {
    var dir = d.dir('dir', [d.file('name.txt', 'contents')]);
    expect(byteStreamToString(dir.load('name.txt')),
        completion(equals('contents')));
  });

  expectTestPasses("directory().load() loads a deeply-nested file", () {
    var dir = d.dir('dir', [
      d.dir('subdir', [
        d.file('name.txt', 'subcontents')
      ]),
      d.file('name.txt', 'contents')
    ]);

    expect(byteStreamToString(dir.load('subdir/name.txt')),
        completion(equals('subcontents')));
  });

  expectTestPasses("directory().load() fails to load a nested directory", () {
    var dir = d.dir('dir', [
      d.dir('subdir', [
        d.file('name.txt', 'subcontents')
      ]),
      d.file('name.txt', 'contents')
    ]);

    expect(dir.load('subdir').toList(), throwsA(predicate(
        (x) => x.toString() == "Couldn't find a readable entry named "
                               "'subdir' within 'dir'.")));
  });

  expectTestPasses("directory().load() fails to load an absolute path", () {
    var dir = d.dir('dir', [d.file('name.txt', 'contents')]);

    expect(dir.load('/name.txt').toList(), throwsArgumentError);
  });

  expectTestPasses("directory().load() fails to load '.', '..', or ''", () {
    var dir = d.dir('dir', [d.file('name.txt', 'contents')]);
    expect(dir.load('.').toList(), throwsArgumentError);
    expect(dir.load('..').toList(), throwsArgumentError);
    expect(dir.load('').toList(), throwsArgumentError);
  });

  expectTestPasses("directory().load() fails to load a file that doesn't exist",
      () {
    var dir = d.dir('dir', [d.file('name.txt', 'contents')]);

    expect(dir.load('not-name.txt').toList(), throwsA(predicate(
        (x) => x.toString() == "Couldn't find a readable entry named "
                               "'not-name.txt' within 'dir'.")));
  });

  expectTestPasses("directory().load() fails to load a file that exists "
      "multiple times", () {
    var dir = d.dir('dir', [
      d.file('name.txt', 'contents'),
      d.file('name.txt', 'contents')
    ]);

    expect(dir.load('name.txt').toList(), throwsA(predicate(
        (x) => x.toString() == "Found multiple readable entries named "
                               "'name.txt' within 'dir'.")));
  });

  expectTestPasses("directory().load() loads a file next to a subdirectory "
      "with the same name", () {
    var dir = d.dir('dir', [
      d.file('name', 'contents'),
      d.dir('name', [d.file('subfile', 'contents')])
    ]);

    expect(byteStreamToString(dir.load('name')),
        completion(equals('contents')));
  });

  expectTestPasses("directory().describe() lists the contents of the directory",
      () {
    var dir = d.dir('dir', [
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]);

    expect(dir.describe(), equals(
        "dir\n"
        "|-- file1.txt\n"
        "'-- file2.txt"));
  });

  expectTestPasses("directory().describe() lists the contents of nested "
      "directories", () {
    var dir = d.dir('dir', [
      d.file('file1.txt', 'contents1'),
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2'),
        d.dir('subsubdir', [
          d.file('subsubfile.txt', 'subsubcontents')
        ])
      ]),
      d.file('file2.txt', 'contents2')
    ]);

    expect(dir.describe(), equals(
        "dir\n"
        "|-- file1.txt\n"
        "|-- subdir\n"
        "|   |-- subfile1.txt\n"
        "|   |-- subfile2.txt\n"
        "|   '-- subsubdir\n"
        "|       '-- subsubfile.txt\n"
        "'-- file2.txt"));
  });

  expectTestPasses("directory().describe() with no contents returns the "
      "directory name", () {
    expect(d.dir('dir').describe(), equals('dir'));
  });

  expectTestPasses("new DirectoryDescriptor().fromFilesystem creates a "
      "descriptor based on the physical filesystem", () {
    scheduleSandbox();

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('subfile2.txt', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('file2.txt', 'contents2')
    ]).create();

    schedule(() {
      var descriptor = new d.DirectoryDescriptor.fromFilesystem(
          "descriptor", path.join(sandbox, 'dir'));
      expect(descriptor, isDirectoryDescriptor('descriptor', [
        isDirectoryDescriptor('subdir', [
          isFileDescriptor('subfile1.txt', 'subcontents1'),
          isFileDescriptor('subfile2.txt', 'subcontents2')
        ]),
        isFileDescriptor('file1.txt', 'contents1'),
        isFileDescriptor('file2.txt', 'contents2')
      ]));
    });
  });

  expectTestPasses("new DirectoryDescriptor().fromFilesystem ignores hidden "
      "files", () {
    scheduleSandbox();

    d.dir('dir', [
      d.dir('subdir', [
        d.file('subfile1.txt', 'subcontents1'),
        d.file('.hidden', 'subcontents2')
      ]),
      d.file('file1.txt', 'contents1'),
      d.file('.DS_Store', 'contents2')
    ]).create();

    schedule(() {
      var descriptor = new d.DirectoryDescriptor.fromFilesystem(
          "descriptor", path.join(sandbox, 'dir'));
      expect(descriptor, isDirectoryDescriptor('descriptor', [
        isDirectoryDescriptor('subdir', [
          isFileDescriptor('subfile1.txt', 'subcontents1')
        ]),
        isFileDescriptor('file1.txt', 'contents1')
      ]));
    });
  });
}
