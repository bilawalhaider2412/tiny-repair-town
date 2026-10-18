import 'dart:convert';
import 'package:test/test.dart';
import 'package:tiny_repair_town/core/save_data.dart';

/// In-memory storage for tests (no filesystem).
class MemoryStorage implements SaveStorage {
  String? primary;
  String? backup;
  int writes = 0;

  @override
  Future<String?> readPrimary() async => primary;

  @override
  Future<String?> readBackup() async => backup;

  @override
  Future<void> writeAll(String content) async {
    writes++;
    backup = primary; // previous good primary becomes the backup
    primary = content;
  }
}

void main() {
  group('SaveData / SaveStore', () {
    test('fresh defaults on first launch', () async {
      final store = await SaveStore.load(MemoryStorage());
      expect(store.recoveredFromCorrupt, isFalse);
      expect(store.data.completedLevels, isEmpty);
      expect(store.data.stickers, isEmpty);
      expect(store.data.language, 'en');
      expect(store.data.saveSchemaVersion, SaveData.currentVersion);
    });

    test('completeLevel is idempotent: no duplicate stickers or completions', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      store.completeLevel('L01', 'sticker_little_wheel');
      store.completeLevel('L01', 'sticker_little_wheel'); // replay
      await store.save();
      expect(store.data.completedLevels.where((l) => l == 'L01').length, 1);
      expect(store.data.stickers.where((s) => s == 'sticker_little_wheel').length, 1);

      // reload from storage: still no duplicates
      final store2 = await SaveStore.load(storage);
      expect(store2.data.completedLevels.where((l) => l == 'L01').length, 1);
      expect(store2.data.stickers.where((s) => s == 'sticker_little_wheel').length, 1);
    });

    test('replay never duplicates stickers across save/load cycles', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      for (var i = 0; i < 5; i++) {
        store.completeLevel('L01', 'sticker_little_wheel');
        await store.save();
      }
      final reloaded = await SaveStore.load(storage);
      expect(reloaded.data.stickers.length, 1);
    });

    test('saves are serialized (no overlapping writes)', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      store.completeLevel('L01', 'sticker_little_wheel');
      // fire several saves concurrently; the store must serialize them
      await Future.wait([store.save(), store.save(), store.save()]);
      expect(storage.writes, 3);
      final reloaded = await SaveStore.load(storage);
      expect(reloaded.data.completedLevels, contains('L01'));
    });

    test('corrupt primary falls back to backup when one exists', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      store.completeLevel('L01', 'sticker_little_wheel');
      await store.save();
      await store.save(); // second save: the previous primary becomes the backup
      storage.primary = 'not valid json {{{'; // corrupt the primary
      final recovered = await SaveStore.load(storage);
      expect(recovered.recoveredFromCorrupt, isFalse); // backup was good
      expect(recovered.data.completedLevels, contains('L01')); // backup restored
    });

    test('corrupt primary with missing backup -> defaults, flagged, no crash', () async {
      final storage = MemoryStorage()..primary = 'not valid json {{{';
      // No backup file at all: the corrupt primary still means progress
      // was lost, so the recovery must be surfaced.
      final store = await SaveStore.load(storage);
      expect(store.recoveredFromCorrupt, isTrue);
      expect(store.data.completedLevels, isEmpty);
      expect(store.data.language, 'en');
    });

    test('corrupt primary AND backup -> fresh defaults, flagged, no crash', () async {
      final storage = MemoryStorage()
        ..primary = 'garbage{{{'
        ..backup = 'also garbage';
      final store = await SaveStore.load(storage);
      expect(store.recoveredFromCorrupt, isTrue);
      expect(store.data.completedLevels, isEmpty);
      expect(store.data.language, 'en');
      // can still save afterwards
      await store.save();
      final reloaded = await SaveStore.load(storage);
      expect(reloaded.recoveredFromCorrupt, isFalse);
    });

    test('migration v1 -> v2 adds extraGuidance default', () async {
      final storage = MemoryStorage();
      final v1 = {
        'saveSchemaVersion': 1,
        'language': 'ur',
        'audio': {'music': true, 'effects': true, 'narration': true},
        'accessibility': {'reducedMotion': true, 'largeText': false},
        'completedLevels': ['L01'],
        'stickers': ['sticker_little_wheel'],
        'currentLevelId': 'L02',
        'checkpoints': {},
        'contentVersion': 1,
        'entitlement': {'productId': 'tiny_repair_town_full_unlock', 'granted': false},
        'parentGate': {},
      };
      storage.primary = jsonEncode(v1);
      final store = await SaveStore.load(storage);
      expect(store.data.saveSchemaVersion, SaveData.currentVersion);
      expect(store.data.accessibility['extraGuidance'], isFalse);
      expect(store.data.language, 'ur'); // preserved
      expect(store.data.completedLevels, contains('L01')); // preserved
      expect(store.data.stickers, contains('sticker_little_wheel')); // preserved, not duplicated
    });

    test('round-trip preserves language and settings', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      store.data.language = 'ur';
      store.data.accessibility['reducedMotion'] = true;
      await store.save();
      final reloaded = await SaveStore.load(storage);
      expect(reloaded.data.language, 'ur');
      expect(reloaded.data.accessibility['reducedMotion'], isTrue);
    });

    test('reset keeps purchase entitlement separate from progress', () async {
      final storage = MemoryStorage();
      final store = await SaveStore.load(storage);
      store.data.entitlement['granted'] = true;
      store.completeLevel('L01', 'sticker_little_wheel');
      await store.save();
      store.resetProgress(); // parent-initiated reset
      await store.save();
      final reloaded = await SaveStore.load(storage);
      expect(reloaded.data.completedLevels, isEmpty);
      expect(reloaded.data.stickers, isEmpty);
      expect(reloaded.data.entitlement['granted'], isTrue); // purchase NOT erased
    });
  });
}
