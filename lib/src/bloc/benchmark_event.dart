import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import 'benchmark_progress.dart';

abstract class BenchmarkEvent extends Equatable {
  const BenchmarkEvent();

  @override
  List<Object?> get props => [];
}

class LoadBenchmarkConfig extends BenchmarkEvent {
  const LoadBenchmarkConfig();
}

class RunBenchmark extends BenchmarkEvent {
  final ScrollController? scrollController;
  final BuildContext? context;
  final TickerProvider? tickerProvider;

  const RunBenchmark({
    this.scrollController,
    this.context,
    this.tickerProvider,
  });

  @override
  List<Object?> get props => [scrollController, context, tickerProvider];
}

/// ✅ user cancels run
class CancelBenchmark extends BenchmarkEvent {
  const CancelBenchmark();
}

class ResetBenchmark extends BenchmarkEvent {
  const ResetBenchmark();
}

/// internal events for streaming (bloc-only usage)
class ProgressUpdated extends BenchmarkEvent {
  final BenchmarkProgress progress;
  const ProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

class DeviceAndOsUpdated extends BenchmarkEvent {
  final DeviceAndOsResult result;
  const DeviceAndOsUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

class PerformanceUpdated extends BenchmarkEvent {
  final PerformanceResult result;
  const PerformanceUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

class FeatureSupportUpdated extends BenchmarkEvent {
  final FeatureSupportResult result;
  const FeatureSupportUpdated(this.result);

  @override
  List<Object?> get props => [result];
}

class ReportReady extends BenchmarkEvent {
  final BenchmarkReport report;
  const ReportReady(this.report);

  @override
  List<Object?> get props => [report];
}
