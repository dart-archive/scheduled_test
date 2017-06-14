**This package is deprecated.** It will not be maintained going forward.

The `scheduled_test` package was originally created before Dart supported
`async` and `await`, as a way to make it possible to write readable asynchronous
tests. Now that `async` and `await` exist, this purpose is no longer relevant.

Most of the features of `scheduled_test` are now available in other packages
that use normal `Future`- and `Stream`-based APIs.

* The `scheduled_test/descriptor` library is replaced by the
  [`test_descriptor`][test_descriptor] package.

* The `scheduled_test/scheduled_process` library is replaced by the
  [`test_process`][test_process] package.

* The `scheduled_test/scheduled_stream` library is replaced by the
  [`StreamQueue`][StreamQueue] in the `async` package as well as the
  [stream matchers][] in the `test` package.

* The `scheduled_test/scheduled_server` library is replaced by the
  [`shelf_test_handler`][shelf_test_handler] package.

[test_descriptor]: https://pub.dartlang.org/packages/test_descriptor
[test_process]: https://pub.dartlang.org/packages/test_process
[StreamQueue]: https://www.dartdocs.org/documentation/async/1.13.3/async/StreamQueue-class.html
[stream matchers]: https://github.com/dart-lang/test#stream-matchers
[shelf_test_handler]: https://pub.dartlang.org/packages/shelf_test_handler
