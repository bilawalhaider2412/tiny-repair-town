/// SaveStorage implementations for the Flutter app.
///
/// The real app persists through [PathProviderSaveStorage] (application
/// documents directory, atomic writes via FileSaveStorage from the pure-Dart
/// package). Widget tests inject [MemorySaveStorage] instead.
library;

import 'package:path_provider/path_provider.dart';
import 'package:tiny_repair_town/core/save_data.dart';

/// Production storage: save.json (+ .bak) under the app documents directory.
class PathProviderSaveStorage implements SaveStorage {
  FileSaveStorage? _impl;

  Future<FileSaveStorage> _storage() async {
    if (_impl != null) return _impl!;
    final dir = await getApplicationDocumentsDirectory();
    _impl = FileSaveStorage(dir.path);
    return _impl!;
  }

  @override
  Future<String?> readPrimary() async => (await _storage()).readPrimary();

  @override
  Future<String?> readBackup() async => (await _storage()).readBackup();

  @override
  Future<void> writeAll(String primary) async =>
      (await _storage()).writeAll(primary);
}

/// In-memory storage for widget tests (no filesystem, no plugins).
class MemorySaveStorage implements SaveStorage {
  String? primary;
  String? backup;

  @override
  Future<String?> readPrimary() async => primary;

  @override
  Future<String?> readBackup() async => backup;

  @override
  Future<void> writeAll(String primary) async {
    if (this.primary != null) backup = this.primary;
    this.primary = primary;
  }
}
