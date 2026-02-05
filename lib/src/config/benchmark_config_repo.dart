import 'package:app_compat_benchmark_core/app_compat_benchmark_core.dart';

import 'config_source.dart';

class BenchmarkConfigRepository {
  final BenchmarkConfigSource? cache;
  final BenchmarkConfigSource? remote;

  const BenchmarkConfigRepository({this.cache, this.remote});

  /// Load config in this order:
  /// 1) Defaults
  /// 2) Merge cached JSON
  /// 3) Merge remote JSON (if available)
  ///
  /// Then return the final config (and optionally JSON you can re-cache).
  Future<BenchmarkConfigLoadResult> load() async {
    final defaults = BenchmarkDefaults.defaults();

    Map<String, dynamic>? cachedJson;
    if (cache != null) {
      cachedJson = await cache!.read();
    }

    var config = BenchmarkConfigMerge.fromJsonOrDefaults(cachedJson);

    Map<String, dynamic>? remoteJson;
    if (remote != null) {
      remoteJson = await remote!.read();
      if (remoteJson != null && remoteJson.isNotEmpty) {
        config = config.mergeJson(remoteJson);
      }
    }

    // JSON to cache should be the final merged config
    final mergedJson = config.toJson();

    return BenchmarkConfigLoadResult(
      config: config,
      mergedJson: mergedJson,
      usedDefaults: identical(config, defaults),
      hadCache: cachedJson != null,
      hadRemote: remoteJson != null,
    );
  }
}

class BenchmarkConfigLoadResult {
  final BenchmarkConfig config;
  final Map<String, dynamic> mergedJson;

  final bool usedDefaults;
  final bool hadCache;
  final bool hadRemote;

  const BenchmarkConfigLoadResult({
    required this.config,
    required this.mergedJson,
    required this.usedDefaults,
    required this.hadCache,
    required this.hadRemote,
  });
}
