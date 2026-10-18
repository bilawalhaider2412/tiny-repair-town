/// Loads versioned level JSON through rootBundle.
///
/// Single-source content: the JSON lives in the pure-Dart package
/// (`tiny_repair_town`), declared as a Flutter asset there, and is read here
/// via `packages/tiny_repair_town/assets/levels/level_<ID>.json`.
/// Engines and validation are never duplicated in the app.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:tiny_repair_town/models/level.dart';

class LevelRepository {
  final Map<String, Level> _levels = {};
  final Map<String, Map<String, dynamic>> _raw = {};

  /// Loads all 20 level files. Throws on missing/invalid content.
  Future<Map<String, Level>> loadCatalog() async {
    _levels.clear();
    _raw.clear();
    for (var n = 1; n <= 20; n++) {
      final id = 'L${n.toString().padLeft(2, '0')}';
      final text = await rootBundle.loadString(
          'packages/tiny_repair_town/assets/levels/level_$id.json');
      final json = jsonDecode(text) as Map<String, dynamic>;
      _raw[id] = json;
      _levels[id] = Level.fromJson(json);
    }
    final errors = Level.validateCatalog(_levels.values.toList());
    if (errors.isNotEmpty) {
      throw StateError('Level catalog invalid: ${errors.join('; ')}');
    }
    return Map.unmodifiable(_levels);
  }

  /// Raw decoded JSON for a level (localized reward/improvement names,
  /// tutorial scripts) — presentation data only, never game rules.
  Map<String, dynamic> rawFor(String levelId) => _raw[levelId] ?? {};
}
