import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';
import 'package:equatable/equatable.dart';
import 'benchmark_progress.dart';

enum BenchmarkRunStatus {
  idle,
  loadingConfig,
  ready,
  running,
  canceled,
  completed,
  error,
}

class BenchmarkState extends Equatable {
  final BenchmarkRunStatus status;

  final BenchmarkConfig? config;
  final Map<String, dynamic>? mergedConfigJson;
  final String? message;

  // ✅ progress streaming
  final BenchmarkProgress? progress;

  // ✅ domain sub-states
  final DeviceAndOsResult? deviceAndOs;
  final PerformanceResult? performance;
  final FeatureSupportResult? featureSupport;

  // final report
  final BenchmarkReport? report;

  const BenchmarkState({
    this.status = BenchmarkRunStatus.idle,
    this.config,
    this.mergedConfigJson,
    this.message,
    this.progress,
    this.deviceAndOs,
    this.performance,
    this.featureSupport,
    this.report,
  });

  BenchmarkState copyWith({
    BenchmarkRunStatus? status,
    BenchmarkConfig? config,
    Map<String, dynamic>? mergedConfigJson,
    String? message,
    BenchmarkProgress? progress,
    DeviceAndOsResult? deviceAndOs,
    PerformanceResult? performance,
    FeatureSupportResult? featureSupport,
    BenchmarkReport? report,
  }) {
    return BenchmarkState(
      status: status ?? this.status,
      config: config ?? this.config,
      mergedConfigJson: mergedConfigJson ?? this.mergedConfigJson,
      message: message,
      progress: progress ?? this.progress,
      deviceAndOs: deviceAndOs ?? this.deviceAndOs,
      performance: performance ?? this.performance,
      featureSupport: featureSupport ?? this.featureSupport,
      report: report ?? this.report,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    mergedConfigJson,
    message,
    progress,
    deviceAndOs,
    performance,
    featureSupport,
    report,
  ];
}
