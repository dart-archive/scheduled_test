// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_process.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';

import 'package:metatest/metatest.dart';
import 'utils.dart';

void main() {
  expectTestFailure("a process must have kill() or shouldExit() called", () {
    startDartProcess('print("hello!");');
  }, (error) {
    expect(error, isStateError);
    expect(error.message, matches(r"^Scheduled process "
        r"'[^']+[\\/]dart(\.exe)?' must have shouldExit\(\) or kill\(\) "
        r"called before the test is run\.$"));
  });

  expectTestsPass("a process exits with the expected exit code", () {
    test('exit code 0', () {
      var process = startDartProcess('exitCode = 0;');
      process.shouldExit(0);
    });

    test('exit code 42', () {
      var process = startDartProcess('exitCode = 42;');
      process.shouldExit(42);
    });
  });

  expectTestFailure("a process exiting with an unexpected exit code should "
      "cause an error", () {
    var process = startDartProcess('exitCode = 1;');
    process.shouldExit(0);
  }, (error) => expect(error, isTestFailure));

  expectTestsPass("a killed process doesn't care about its exit code", () {
    test('exit code 0', () {
      var process = startDartProcess('exitCode = 0;');
      process.kill();
    });

    test('exit code 1', () {
      var process = startDartProcess('exitCode = 1;');
      process.kill();
    });
  });

  expectTestPasses("a killed process stops running", () {
    var process = startDartProcess('while (true);');
    process.kill();
  });

  expectTestPasses("kill can't be called twice", () {
    var process = startDartProcess('');
    process.kill();
    expect(process.kill, throwsA(isStateError));
  });

  expectTestPasses("kill can't be called after shouldExit", () {
    var process = startDartProcess('');
    process.shouldExit(0);
    expect(process.kill, throwsA(isStateError));
  });

  expectTestPasses("shouldExit can't be called twice", () {
    var process = startDartProcess('');
    process.shouldExit(0);
    expect(() => process.shouldExit(0), throwsA(isStateError));
  });

  expectTestPasses("shouldExit can't be called after kill", () {
    var process = startDartProcess('');
    process.kill();
    expect(() => process.shouldExit(0), throwsA(isStateError));
  });

  expectTestFails("a process that ends while waiting for stdout shouldn't "
      "block the test", () {
    var process = startDartProcess('');
    process.stdout.expect('hello');
    process.stdout.expect('world');
    process.shouldExit(0);
  }, (errors) {
    expect(errors.length, anyOf(1, 2));
    expect(errors[0].error, isTestFailure);
    expect(errors[0].error.message, equals(
        "Expected: 'hello'\n"
        " Emitted: \n"
        "   Which: unexpected end of stream"));

    // Whether or not this error appears depends on how quickly the "no
    // elements" error is handled.
    if (errors.length == 2) {
      expect(errors[1].error.toString(), matches(r"^Process "
          r"'[^']+[\\/]dart(\.exe)? [^']+' ended earlier than scheduled with "
          r"exit code 0\."));
    }
  });

  expectTestPasses("a process that ends during the task immediately before "
      "it's scheduled to end shouldn't cause an error", () {
    var process = startDartProcess('stdin.toList();');
    process.closeStdin();
    // Unfortunately, sleeping for a second seems like the best way of
    // guaranteeing that the process ends during this task.
    schedule(() => new Future.delayed(new Duration(seconds: 1)));
    process.shouldExit(0);
  });

  expectTestPasses("stdout exposes the standard output from the process", () {
    var process = startDartProcess(r'print("hello\n\nworld"); print("hi");');
    process.stdout.expect('hello');
    process.stdout.expect('');
    process.stdout.expect('world');
    process.stdout.expect('hi');
    process.stdout.expect(isDone);
    process.shouldExit(0);
  });

  expectTestPasses("stderr exposes the stderr from the process", () {
    var process = startDartProcess(r'''
        stderr.write("hello\n\nworld\n");
        stderr.write("hi");
        ''');
    process.stderr.expect('hello');
    process.stderr.expect('');
    process.stderr.expect('world');
    process.stderr.expect('hi');
    process.stderr.expect(isDone);
    process.shouldExit(0);
  });

  expectTestPasses("writeLine schedules a line to be written to the process",
      () {
    var process = startDartProcess(r'''
        stdinLines.listen((line) => print("> $line"));
        ''');
    process.writeLine("hello");
    process.stdout.expect("> hello");
    process.writeLine("world");
    process.stdout.expect("> world");
    process.kill();
  });

  expectTestPasses("closeStdin closes the process's stdin stream", () {
    var process = startDartProcess(r'''
        stdin.listen((line) => print("> $line"),
            onDone: () => print("stdin closed"));
        ''');
    process.closeStdin();
    process.shouldExit(0);
    process.stdout.expect('stdin closed');
  });

  expectTestPasses("signal sends a signal to the subprocess", () {
    var process = startDartProcess(r'''
ProcessSignal.SIGHUP.watch().listen((_) => print("HUP"));
print("ready");
''');
    process.stdout.expect('ready');
    process.signal(ProcessSignal.SIGHUP);
    process.stdout.expect('HUP');
    process.kill();
  }, testOn: "!windows");
}

ScheduledProcess startDartProcess(String script) {
  var tempDir = schedule(() => Directory.systemTemp
                                        .createTemp('scheduled_process_test_')
                                        .then((dir) => dir.path),
                         'create temp dir');
  var dartPath = schedule(() {
    return tempDir.then((dir) {
      return new File(path.join(dir, 'test.dart')).writeAsString('''
          import 'dart:async';
          import 'dart:convert';
          import 'dart:io';

          var stdinLines = stdin
              .transform(UTF8.decoder)
              .transform(new LineSplitter());

          void main() {
            $script
          }
          ''').then((file) => file.path);
    });
  }, 'write script file');

  currentSchedule.onComplete.schedule(() {
    return tempDir.catchError((_) => null).then((dir) {
      if (dir == null) return null;
      return new Directory(dir).delete(recursive: true);
    });
  }, 'clean up temp dir');

  return new ScheduledProcess.start(Platform.executable,
      ['--checked', dartPath]);
}
