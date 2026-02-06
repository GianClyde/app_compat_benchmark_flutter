import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart'
    hide BenchmarkDomain;
import 'package:async/async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/benchmark_config_repo.dart';
import 'benchmark_event.dart';
import 'benchmark_progress.dart';
import 'benchmark_state.dart';

class BenchmarkBloc extends Bloc<BenchmarkEvent, BenchmarkState> {
  final BenchmarkConfigRepository configRepo;

  // services from core (already plugin-backed runners injected into services)
  final DeviceAndOsService deviceAndOsService;
  final PerformanceService performanceService;
  final FeatureSupportService featureSupportService;

  CancelableOperation<void>? _runningOp;

  BenchmarkBloc({
    required this.configRepo,
    required this.deviceAndOsService,
    required this.performanceService,
    required this.featureSupportService,
  }) : super(const BenchmarkState()) {
    on<LoadBenchmarkConfig>(_onLoadConfig);

    on<RunBenchmark>(_onRunBenchmark);
    on<CancelBenchmark>(_onCancel);

    // internal stream events
    on<ProgressUpdated>(
      (e, emit) => emit(state.copyWith(progress: e.progress)),
    );
    on<DeviceAndOsUpdated>(
      (e, emit) => emit(state.copyWith(deviceAndOs: e.result)),
    );
    on<PerformanceUpdated>(
      (e, emit) => emit(state.copyWith(performance: e.result)),
    );
    on<FeatureSupportUpdated>(
      (e, emit) => emit(state.copyWith(featureSupport: e.result)),
    );
    on<ReportReady>(
      (e, emit) => emit(
        state.copyWith(status: BenchmarkRunStatus.completed, report: e.report),
      ),
    );

    on<ResetBenchmark>(_onReset);
  }

  Future<void> _onLoadConfig(
    LoadBenchmarkConfig event,
    Emitter<BenchmarkState> emit,
  ) async {
    emit(
      state.copyWith(status: BenchmarkRunStatus.loadingConfig, message: null),
    );
    try {
      final result = await configRepo.load();
      emit(
        state.copyWith(
          status: BenchmarkRunStatus.ready,
          config: result.config,
          mergedConfigJson: result.mergedJson,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BenchmarkRunStatus.error,
          message: "Failed to load benchmark config: $e",
        ),
      );
    }
  }

  Future<void> _onRunBenchmark(
    RunBenchmark event,
    Emitter<BenchmarkState> emit,
  ) async {
    // prevent parallel runs
    await _runningOp?.cancel();
    _runningOp = null;

    final config = state.config ?? BenchmarkDefaults.defaults();

    // progress plan
    final rules = config.featureSupport.buildRules();
    const perfSteps =
        4; // idle/scroll/navigation/animation (matches plugin runner)
    final planner = ProgressPlanner(
      performanceSteps: perfSteps,
      featureSteps: rules.length,
    );
    var tick = 0;

    void progress(BenchmarkDomain domain, String label, {String? stepKey}) {
      tick++;
      final fraction = tick / planner.totalTicks;
      add(
        ProgressUpdated(
          BenchmarkProgress(
            domain: domain,
            fraction: fraction,
            label: label,
            stepKey: stepKey,
          ),
        ),
      );
    }

    emit(
      state.copyWith(
        status: BenchmarkRunStatus.running,
        message: null,
        progress: BenchmarkProgress(
          domain: BenchmarkDomain.overall,
          fraction: 0,
          label: "Starting…",
        ),
        deviceAndOs: null,
        performance: null,
        featureSupport: null,
        report: null,
      ),
    );

    _runningOp = CancelableOperation.fromFuture(
      () async {
        // 1) Device & OS
        progress(BenchmarkDomain.deviceAndOs, "Checking device & OS…");
        final dos = await deviceAndOsService.run(config);
        add(DeviceAndOsUpdated(dos));

        if (dos.hardBlocked) {
          // short-circuit report
          progress(BenchmarkDomain.overall, "Blocked by device requirements");
          final perf = PerformanceResult(
            rawResults: const [],
            stepScores: const [],
            score: 0,
            rating: "❌ Incompatible",
            hardBlocked: true,
          );
          final feat = FeatureSupportResult(
            results: const [],
            score: const FeatureSupportScore(
              featureScores: {},
              overallScore: 0,
              isBlocked: true,
            ),
            hardBlocked: true,
          );

          final report = BenchmarkReport.fromDomainScores(
            config: config,
            deviceAndOs: dos,
            performance: perf,
            featureSupport: feat,
          );

          add(ReportReady(report));
          return;
        }

        // 2) Performance – stream step-level progress even though the runner returns at end.
        // We emit progress ticks per step name (UI-friendly). (Runner runs steps internally.)
        // If you want *true* per-step results streaming, we can add a callback to plugin runner later.
        progress(
          BenchmarkDomain.performance,
          "Benchmark idle…",
          stepKey: BenchmarkStepType.idle.name,
        );
        progress(
          BenchmarkDomain.performance,
          "Benchmark scroll…",
          stepKey: BenchmarkStepType.scroll.name,
        );
        progress(
          BenchmarkDomain.performance,
          "Benchmark navigation…",
          stepKey: BenchmarkStepType.navigation.name,
        );
        progress(
          BenchmarkDomain.performance,
          "Benchmark animation…",
          stepKey: BenchmarkStepType.animation.name,
        );

        final perf = await performanceService.run(
          config: config,
          context: PerformanceRunContext(
            scrollHandle: event.scrollController,
            navHandle: event.context,
            tickerHandle: event.tickerProvider,
          ),
        );
        add(PerformanceUpdated(perf));

        // 3) Feature support – we *can* truly stream per feature because runner checks per step
        for (final rule in rules) {
          progress(
            BenchmarkDomain.featureSupport,
            "Checking ${rule.type.name}…",
            stepKey: rule.type.name,
          );
          // FeatureSupportService currently runs all rules internally.
          // To stream actual results per feature, we do it here directly:
        }

        // Run it fully (final results)
        final feat = await featureSupportService.run(config);
        add(FeatureSupportUpdated(feat));

        // 4) Build report
        progress(BenchmarkDomain.overall, "Finalizing report…");
        final report = BenchmarkReport.fromDomainScores(
          config: config,
          deviceAndOs: dos,
          performance: perf,
          featureSupport: feat,
        );
        add(ReportReady(report));
      }(),
      onCancel: () async {
        // cleanup hook if needed
      },
    );

    try {
      await _runningOp!.value;
    } catch (e, st) {
      // ignore: avoid_print
      print("BENCHMARK ERROR: $e\n$st");

      if (_runningOp?.isCanceled == true) {
        emit(
          state.copyWith(
            status: BenchmarkRunStatus.canceled,
            message: "Benchmark canceled",
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: BenchmarkRunStatus.error,
          message: "Benchmark failed: $e",
        ),
      );
    } finally {
      _runningOp = null;
    }
  }

  Future<void> _onCancel(
    CancelBenchmark event,
    Emitter<BenchmarkState> emit,
  ) async {
    await _runningOp?.cancel();
    _runningOp = null;
    emit(
      state.copyWith(
        status: BenchmarkRunStatus.canceled,
        message: "Benchmark canceled",
      ),
    );
  }

  void _onReset(ResetBenchmark event, Emitter<BenchmarkState> emit) {
    _runningOp?.cancel();
    _runningOp = null;
    emit(const BenchmarkState());
  }

  @override
  Future<void> close() async {
    await _runningOp?.cancel();
    return super.close();
  }
}
