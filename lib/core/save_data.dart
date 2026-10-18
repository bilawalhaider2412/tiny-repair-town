/// Save data: storage abstraction, file implementation, data model and store.
///
/// Contract: `docs/CONTENT_SCHEMA.md` § "Save data". Pure Dart — `dart:io`
/// is used only inside [FileSaveStorage]; everything else is io-free.
library;

import 'dart:convert';
import 'dart:io';

/// Storage abstraction so the store can be unit-tested without a filesystem.
abstract class SaveStorage {
  /// Reads the primary save file, or null when missing/unreadable.
  Future<String?> readPrimary();

  /// Reads the backup save file, or null when missing/unreadable.
  Future<String?> readBackup();

  /// Persists [primary] content (implementations also keep a backup).
  Future<void> writeAll(String primary);
}

/// File-based [SaveStorage].
///
/// Writes are atomic (temp file + rename) and the previous good primary is
/// kept as a `.bak` copy, so a crash mid-write never loses both copies.
class FileSaveStorage implements SaveStorage {
  /// Directory that holds the save files.
  final String directoryPath;

  FileSaveStorage(this.directoryPath);

  File get _primaryFile => File('$directoryPath/save.json');
  File get _backupFile => File('$directoryPath/save.json.bak');
  File get _tempFile => File('$directoryPath/save.json.tmp');

  @override
  Future<String?> readPrimary() => _read(_primaryFile);

  @override
  Future<String?> readBackup() => _read(_backupFile);

  @override
  Future<void> writeAll(String primary) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) await dir.create(recursive: true);
    // 1. Write the new content to a temp file, then fsync it.
    final temp = _tempFile;
    await temp.writeAsString(primary, flush: true);
    // 2. Keep the previous good primary as the backup.
    if (await _primaryFile.exists()) {
      await _primaryFile.copy(_backupFile.path);
    }
    // 3. Atomically promote the temp file to the primary.
    await temp.rename(_primaryFile.path);
  }

  Future<String?> _read(File file) async {
    try {
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }
}

/// Player save data (schema version 2).
class SaveData {
  /// Current save-schema version.
  static const int currentSaveSchemaVersion = 2;

  /// Alias used by callers that refer to the schema version generically.
  static int get currentVersion => currentSaveSchemaVersion;

  final int saveSchemaVersion;

  /// 'en' | 'ur'. Mutable so the settings UI can switch languages in place.
  String language;

  /// e.g. {"music": true, "effects": true, "narration": true}.
  final Map<String, dynamic> audio;

  /// e.g. {"reducedMotion": false, "extraGuidance": false, "largeText": false}.
  final Map<String, dynamic> accessibility;

  /// Completed level ids, e.g. ["L01"].
  final List<String> completedLevels;

  /// Earned sticker ids.
  final List<String> stickers;

  /// Level the town map highlights, or null.
  final String? currentLevelId;

  /// Per-level engine checkpoints, e.g. {"L20": {"completedStages": [...]}}.
  final Map<String, dynamic> checkpoints;

  /// Content version of the level JSONs this save was written against.
  final int contentVersion;

  /// e.g. {"productId": ..., "granted": false, "verifiedAt": null,
  /// "method": "none"}.
  ///
  /// CACHE ONLY — never treat `granted` as purchase verification (spec §18).
  /// Production verification is server-side once the owner sets up billing;
  /// this flag only remembers a previously verified grant for offline access.
  final Map<String, dynamic> entitlement;

  /// e.g. {"pinSet": false}.
  final Map<String, dynamic> parentGate;

  /// Note: not const — [language] is mutable so the settings UI can switch
  /// languages in place on the live save object.
  SaveData({
    required this.saveSchemaVersion,
    required this.language,
    required this.audio,
    required this.accessibility,
    required this.completedLevels,
    required this.stickers,
    required this.currentLevelId,
    required this.checkpoints,
    required this.contentVersion,
    required this.entitlement,
    required this.parentGate,
  });

  /// Fresh defaults for a first-time player.
  factory SaveData.defaults() => SaveData(
        saveSchemaVersion: currentSaveSchemaVersion,
        language: 'en',
        audio: {'music': true, 'effects': true, 'narration': true},
        accessibility: {
          'reducedMotion': false,
          'extraGuidance': false,
          'largeText': false,
        },
        completedLevels: [],
        stickers: [],
        currentLevelId: 'L01',
        checkpoints: {},
        contentVersion: 1,
        entitlement: {
          'productId': 'tiny_repair_town_full_unlock',
          'granted': false,
          'verifiedAt': null,
          'method': 'none',
        },
        parentGate: {'pinSet': false},
      );

  /// Parses save JSON defensively (missing keys fall back to defaults) and
  /// migrates older schema versions in place.
  factory SaveData.fromJson(Map<String, dynamic> json) {
    applyMigration(json);
    List<String> strings(dynamic v) =>
        (v as List? ?? []).map((e) => e.toString()).toList();
    final audio = (json['audio'] as Map? ?? {}).cast<String, dynamic>();
    final accessibility =
        (json['accessibility'] as Map? ?? {}).cast<String, dynamic>();
    final checkpoints =
        (json['checkpoints'] as Map? ?? {}).cast<String, dynamic>();
    final entitlement =
        (json['entitlement'] as Map? ?? {}).cast<String, dynamic>();
    final parentGate =
        (json['parentGate'] as Map? ?? {}).cast<String, dynamic>();
    final language = json['language']?.toString() ?? 'en';
    return SaveData(
      saveSchemaVersion:
          (json['saveSchemaVersion'] as num?)?.toInt() ??
              currentSaveSchemaVersion,
      language: (language == 'ur') ? 'ur' : 'en',
      audio: {
        'music': audio['music'] != false,
        'effects': audio['effects'] != false,
        'narration': audio['narration'] != false,
      },
      accessibility: {
        'reducedMotion': accessibility['reducedMotion'] == true,
        'extraGuidance': accessibility['extraGuidance'] == true,
        'largeText': accessibility['largeText'] == true,
      },
      completedLevels: strings(json['completedLevels']),
      stickers: strings(json['stickers']),
      currentLevelId: json['currentLevelId']?.toString(),
      checkpoints: checkpoints,
      contentVersion: (json['contentVersion'] as num?)?.toInt() ?? 1,
      entitlement: {
        'productId': entitlement['productId']?.toString() ??
            'tiny_repair_town_full_unlock',
        'granted': entitlement['granted'] == true,
        'verifiedAt': entitlement['verifiedAt']?.toString(),
        'method': entitlement['method']?.toString() ?? 'none',
      },
      parentGate: {'pinSet': parentGate['pinSet'] == true},
    );
  }

  /// Migrates a raw save JSON map forward in place.
  ///
  /// v1 -> v2: adds `accessibility.extraGuidance` (default false) and bumps
  /// `saveSchemaVersion` to 2.
  static void applyMigration(Map<String, dynamic> json) {
    final version = (json['saveSchemaVersion'] as num?)?.toInt() ?? 1;
    if (version < 2) {
      final accessibility =
          (json['accessibility'] as Map?)?.cast<String, dynamic>() ?? {};
      accessibility.putIfAbsent('extraGuidance', () => false);
      json['accessibility'] = accessibility;
      json['saveSchemaVersion'] = 2;
    }
  }

  /// Serialises to the on-disk JSON shape.
  Map<String, dynamic> toJson() => {
        'saveSchemaVersion': saveSchemaVersion,
        'language': language,
        'audio': audio,
        'accessibility': accessibility,
        'completedLevels': completedLevels,
        'stickers': stickers,
        'currentLevelId': currentLevelId,
        'checkpoints': checkpoints,
        'contentVersion': contentVersion,
        'entitlement': entitlement,
        'parentGate': parentGate,
      };
}

/// Owns a [SaveData] and persists it through a [SaveStorage].
class SaveStore {
  final SaveStorage _storage;

  /// The live save data.
  SaveData data;

  /// True when both primary and backup were corrupt and defaults were used.
  final bool recoveredFromCorrupt;

  /// Serialises saves so writes never overlap.
  Future<void> _pending = Future.value();

  SaveStore._(this._storage, this.data, this.recoveredFromCorrupt);

  /// Loads the store: primary first, then backup; when both copies exist but
  /// are corrupt, falls back to defaults with [recoveredFromCorrupt] set.
  /// A missing save (first launch) also yields defaults, but is *not*
  /// flagged as a corruption recovery.
  static Future<SaveStore> load(SaveStorage storage) async {
    SaveData? parsed;
    var primaryCorrupt = false;
    var backupCorrupt = false;
    var backupMissing = false;

    final rawPrimary = await storage.readPrimary();
    if (rawPrimary != null) {
      try {
        parsed = SaveData.fromJson(
            (jsonDecode(rawPrimary) as Map).cast<String, dynamic>());
      } catch (_) {
        primaryCorrupt = true;
      }
    }
    if (parsed == null) {
      final rawBackup = await storage.readBackup();
      if (rawBackup == null) {
        backupMissing = true;
      } else {
        try {
          parsed = SaveData.fromJson(
              (jsonDecode(rawBackup) as Map).cast<String, dynamic>());
        } catch (_) {
          backupCorrupt = true;
        }
      }
    }
    if (parsed == null) {
      parsed = SaveData.defaults();
    }
    // A corrupt primary with no usable backup means real progress was lost:
    // surface it even when the backup file is simply absent.
    final lost = primaryCorrupt && (backupCorrupt || backupMissing);
    return SaveStore._(storage, parsed, lost);
  }

  /// Persists [data]. Calls are serialised via chained futures so concurrent
  /// saves never interleave.
  Future<void> save() {
    _pending = _pending.then((_) => _storage.writeAll(jsonEncode(data.toJson())));
    return _pending;
  }

  /// Records a level completion. Idempotent: completing the same level twice
  /// never duplicates stickers or completion entries.
  ///
  /// [currentLevelId] moves to the next uncompleted level (L01..L20) when one
  /// can be determined, otherwise it is left unchanged.
  void completeLevel(String levelId, String rewardId) {
    if (!data.completedLevels.contains(levelId)) {
      data = _copyWith(
        completedLevels: [...data.completedLevels, levelId],
      );
    }
    if (!data.stickers.contains(rewardId)) {
      data = _copyWith(stickers: [...data.stickers, rewardId]);
    }
    for (var n = 1; n <= 20; n++) {
      final id = 'L${n.toString().padLeft(2, '0')}';
      if (!data.completedLevels.contains(id)) {
        data = _copyWith(currentLevelId: id);
        return;
      }
    }
    // All levels complete: keep the current level id.
  }

  /// Parent-initiated progress reset: clears completions, stickers and
  /// checkpoints, but keeps the purchase entitlement (and settings) intact.
  void resetProgress() {
    data = SaveData(
      saveSchemaVersion: data.saveSchemaVersion,
      language: data.language,
      audio: data.audio,
      accessibility: data.accessibility,
      completedLevels: [],
      stickers: [],
      currentLevelId: 'L01',
      checkpoints: {},
      contentVersion: data.contentVersion,
      entitlement: data.entitlement,
      parentGate: data.parentGate,
    );
  }

  SaveData _copyWith({
    List<String>? completedLevels,
    List<String>? stickers,
    String? currentLevelId,
  }) {
    return SaveData(
      saveSchemaVersion: data.saveSchemaVersion,
      language: data.language,
      audio: data.audio,
      accessibility: data.accessibility,
      completedLevels: completedLevels ?? data.completedLevels,
      stickers: stickers ?? data.stickers,
      currentLevelId: currentLevelId ?? data.currentLevelId,
      checkpoints: data.checkpoints,
      contentVersion: data.contentVersion,
      entitlement: data.entitlement,
      parentGate: data.parentGate,
    );
  }
}
