A package for writing readable tests of asynchronous behavior.

This package works by building up a queue of asynchronous tasks called a
"schedule", then executing those tasks in order. This allows the tests to
read like synchronous, linear code, despite executing asynchronously.

The `scheduled_test` package is built on top of the `test` package, and should
be imported instead of `test`. It provides its own version of `group()`,
`test()`, `setUp()`, and `tearDown()`, and re-exports most other APIs from
`test`.

To schedule a task, call the `schedule()` function. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('writing to a file and reading it back should work', () {
    schedule(() {
      // The schedule won't proceed until the returned Future has
      // completed.
      return new File("output.txt").writeAsString("contents");
    });

    schedule(() async {
      var contents = await new File("output.txt").readAsString();

      // The normal unittest matchers can still be used.
      expect(contents, equals("contents"));
    });
  });
}
```

## Setting up and tearing down

The `scheduled_test` package defines its own `setUp()` method that works just
like the one in `test`. Tasks can be scheduled in `setUp()`; they'll be run
before the tasks scheduled by tests in that group. `currentSchedule` is also set
in the `setUp()` callback.

Similarly, tasks to run after all the tests in the group can be scheduled using
`tearDown()`. However, the best way to clean up after a test is to add callbacks
to the `onComplete` queue. This queue will always run after the test, whether or
not it succeeded. For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  var tempDir;
  setUp(() {
    schedule(() async {
      tempDir = await createTempDir();
    });

    currentSchedule.onComplete.schedule(() => deleteDir(tempDir));
  });

  // ...
}
```

## Passing values between tasks

It's often useful to use values computed in one task in other tasks that are
scheduled afterwards. There are two ways to do this. The most
straightforward is just to define a local variable and assign to it. For
example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('computeValue returns 12', () {
    var value;

    schedule(() async {
      value = await computeValue();
    });

    schedule(() => expect(value, equals(12)));
  });
}
```

However, this doesn't scale well, especially when you start factoring out calls
to `schedule()` into library methods. For that reason, `schedule()` returns a
`Future` that will complete to the same value as the return value of the task.
For example:

```dart
import 'package:scheduled_test/scheduled_test.dart';

void main() {
  test('computeValue returns 12', () {
    var valueFuture = schedule(() => computeValue());
    schedule(() {
      expect(valueFuture, completion(equals(12)));
    });
  });
}
```
