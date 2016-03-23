## 0.12.5+3

* Declare compatibility with `test` version `0.12.13`.

## 0.12.5+2

* Declare compatibility with `test` version `0.12.12`.

## 0.12.5+1

* Declare compatibility with `test` version `0.12.11`.

## 0.12.5

* Add a `tags` parameter to `test()` and `group()`.

## 0.12.4+6

* Declare compatibility with `test` version `0.12.10`.

## 0.12.4+5

* Declare compatibility with `shelf` version `0.7.0`.

* Declare compatibility with `test` version `0.12.9`.

## 0.12.4+4

* Declare compatibility with `test` version `0.12.8`.

## 0.12.4+3

* Declare compatibility with `test` version `0.12.7`.

## 0.12.4+2

* Declare compatibility with `http_multi_server` version `2.0.0`.

## 0.12.4+1

* Update the dependency on `test` to include `0.12.6`.

## 0.12.4

* Update the dependency on `test` to include `0.12.5`.

## 0.12.3

* Update the dependency on `test` to include `0.12.4`.

## 0.12.2

* Add `ScheduledServer.handleUnscheduled`, which allows users to create
  long-lasting handlers that aren't part of the test schedule.

* Support WebSocket connections with `ScheduledServer`s.

## 0.12.1+2

* Fix running scheduled tests via `dart path/to/test.dart`.

## 0.12.1+1

* Fixed usage of `timeout` in `test` and `group`.

## 0.12.1

* Add named parameters to the wrapper `test()` and `group()` methods that
  forward to the `test` package.

## 0.12.0

* When an error occurs in the tasks queue, the `onComplete` queue will begin
  running immediately rather than waiting for all outstanding tasks and
  out-of-band callbacks to complete. This more closely matches the semantics of
  the underlying test framework and will hopefully be less surprising.

* Errors are now only converted to `ScheduleErrors` when they're added to the
  `Schedule.errors` list. This means that errors emitted by calls to
  `schedule()` will no longer be `ScheduleError`s.

* An error thrown in one task will no longer be emitted by the return values of
  future calls to `schedule()`.

* Remove the `Schedule.onException` queue. This was largely redundant with
  `Schedule.onComplete` and complicated the implementation.

* Remove `Schedule.pendingCallbacks` and `ScheduleError.pendingCallbacks`.
  Printing out the pending callbacks was rarely useful once stack chains
  existed, so they were just producing visual clutter.

* Remove `Schedule.timeout` and `Schedule.heartbeat`. Timeouts will be handled
  by the `test` package instead.

* Remove `Schedule.signalError`. Use `registerException` from the `test` package
  instead.

* Remove `wrapFuture`, `Schedule.wrapFuture`, and `Schedule.wrapAsync`. Use
  `expectAsync`, `completes`, and `completion` from the `test` package instead.

* Remove `TaskQueue.onTasksComplete`.

## 0.11.8+1

* Bump the version constraint for `unittest`.

## 0.11.8

* Add a `ScheduledProcess.signal()` method for sending signals to subprocesses.

## 0.11.7+1

* Support version `0.6.0` of `shelf`.

## 0.11.7

* Bumped the version constraint for `unittest`.

## 0.11.6

* *Actually* bump the version constraint for `unittest`.

## 0.11.5

* Bump the version constraint for `unittest`.

## 0.11.4

* Bump the version constraint for `unittest`.

## 0.11.3

* Narrow the constraint on unittest to ensure that new features are reflected in
  scheduled_test's version.

## 0.11.2+3

* Ignore hidden files in `DirectoryDescriptor.fromFilesystem`.

## 0.11.2+2

* Moved shared test utilities to `metatest` package.

## 0.11.2+1

* Fix a case where a `ScheduledProcess` could fail to log its output.

## 0.11.2

* Add a `DirectoryDescriptor.fromFilesystem` constructor.

## 0.11.1

* Add a top-level `tearDown` function.

## 0.11.0+7

* A `nothing()` descriptor will fail if a broken symlink is present.

## 0.11.0+6

* Use `http_multi_server` to bind to both the IPv4 and IPv6 loopback addresses
  for scheduled_test.

## 0.11.0+5

* Widen the version constraint for `stack_trace`.

## 0.11.0+4

* Added `README.md` with content from `lib/scheduled_test.dart`.

* Made changes to `test/metatest.dart` related to outstanding issues.

## 0.11.0+3

* Support `v0.11.0` of `unittest`.

## 0.11.0+1

* Support `v0.5.0` of `shelf`.

## 0.11.0

* `ScheduledServer.handle` now takes a `shelf.Handler` rather than a custom
  handler class.

* The body of a `test()` or a `setUp()` call may now return a Future. This was
  already supported by the `unittest` package. The Future is passed to a
  `wrapFuture` call.

## 0.10.1+1

* Updated `http` version constraint from `">=0.9.0 <0.10.0"` to
  `">=0.9.0 <0.11.0"`

## 0.10.1

* Add a `StreamMatcher.hasMatch` method.

* The `consumeThrough` and `consumeWhile` matchers for `ScheduledStream` now
  take `StreamMatcher`s as well as normal `Matcher`s.

## 0.10.0

* Convert `ScheduledProcess` to expose `stdout` and `stderr` as
  `ScheduledStream`s.

* Add a `consumeWhile` matcher for `ScheduledStream`.
