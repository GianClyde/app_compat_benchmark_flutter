import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';

typedef LogFn = void Function(String);

class BenchmarkLoggerAdapter implements BenchmarkLogger {
  final LogFn debug;
  final LogFn error;

  const BenchmarkLoggerAdapter({required this.debug, required this.error});

  @override
  void d(String message) => debug(message);

  @override
  void e(String message, [Object? errorObj, StackTrace? stackTrace]) {
    final extra = [
      if (errorObj != null) "error=$errorObj",
      if (stackTrace != null) "stack=$stackTrace",
    ].join(" | ");
    error(extra.isEmpty ? message : "$message | $extra");
  }
}
