/// A JSON source for benchmark config (cache, remote, etc).
abstract interface class BenchmarkConfigSource {
  Future<Map<String, dynamic>?> read(); // returns JSON map or null
}

/// For remote, you can implement this by calling your API.
/// For cache, implement using SharedPreferences or secure storage.
/// We intentionally keep this package storage-agnostic.
