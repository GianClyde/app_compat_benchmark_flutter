import 'package:equatable/equatable.dart';

enum BenchmarkDomain { deviceAndOs, performance, featureSupport, overall }

class BenchmarkProgress extends Equatable {
  final BenchmarkDomain domain;

  /// Optional: performance step, feature type, etc.
  final String? stepKey;

  /// 0..1 for progress bars (you control how you compute it)
  final double fraction;

  /// Friendly label for UI
  final String label;

  const BenchmarkProgress({
    required this.domain,
    required this.fraction,
    required this.label,
    this.stepKey,
  });

  @override
  List<Object?> get props => [domain, stepKey, fraction, label];
}

/// A simple progress plan:
/// Device&OS (1 tick), Performance (N steps), FeatureSupport (M rules), Overall finalize (1 tick)
class ProgressPlanner {
  final int performanceSteps;
  final int featureSteps;

  const ProgressPlanner({
    required this.performanceSteps,
    required this.featureSteps,
  });

  int get totalTicks => 1 + performanceSteps + featureSteps + 1;
}
