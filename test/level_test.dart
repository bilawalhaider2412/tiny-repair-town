import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:tiny_repair_town/models/level.dart';
import 'package:tiny_repair_town/puzzles/match_parts.dart';
import 'package:tiny_repair_town/puzzles/build_order.dart';
import 'package:tiny_repair_town/puzzles/restore_pattern.dart';

final levelsDir = Directory('/home/hatch/workspace/tiny-repair-town/assets/levels');

List<Level> loadCatalog() {
  final files = levelsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return files
      .map((f) => Level.fromJson(jsonDecode(f.readAsStringSync()) as Map<String, dynamic>))
      .toList();
}

void main() {
  group('Level content validation', () {
    late List<Level> catalog;
    setUpAll(() => catalog = loadCatalog());

    test('exactly 20 unique ids L01..L20', () {
      final ids = catalog.map((l) => l.id).toList();
      expect(ids.toSet().length, 20);
      for (var i = 1; i <= 20; i++) {
        expect(ids, contains('L${i.toString().padLeft(2, '0')}'));
      }
    });

    test('tiers match launch table: L01-L10 free, L11-L20 pack', () {
      for (final l in catalog) {
        final n = int.parse(l.id.substring(1));
        expect(l.accessTier, n <= 10 ? 'free' : 'pack', reason: l.id);
      }
    });

    test('catalog has no missing prerequisites and no cycles', () {
      expect(Level.validateCatalog(catalog), isEmpty);
    });

    test('L01, L03 and L04 are fully authored and playable', () {
      // The three system showcases must always be real, playable content.
      final authored = {'L01', 'L03', 'L04'};
      for (final l in catalog.where((l) => authored.contains(l.id))) {
        expect(l.stub, isFalse, reason: l.id);
        expect(l.isPlayable, isTrue, reason: l.id);
        expect(l.hints.length, 3, reason: l.id);
        expect(l.validate(), isEmpty, reason: l.id);
      }
    });

    test('every level honours the stub contract', () {
      // Contract (holds at every stage of content authoring, so this test
      // never needs updating as stubs become real levels):
      // - stub levels are never playable and are never shown as playable;
      // - non-stub levels are fully specified and validate cleanly.
      for (final l in catalog) {
        expect(l.validate(), isEmpty, reason: l.id);
        if (l.stub) {
          expect(l.isPlayable, isFalse, reason: l.id);
        } else {
          expect(l.isPlayable, isTrue, reason: l.id);
          expect(l.hints.length, 3, reason: l.id);
        }
      }
    });

    test('L01 is solvable through the match-parts engine', () {
      final l01 = catalog.firstWhere((l) => l.id == 'L01');
      final engine = MatchPartsEngine.fromConfig(l01.config);
      for (final slot in engine.slots) {
        final result = engine.tryPlace(slot.acceptsPartId, slot.id);
        expect(result.correct, isTrue,
            reason: 'placing ${slot.acceptsPartId} into ${slot.id}');
        engine.unlockInput();
      }
      expect(engine.isComplete, isTrue);
    });

    test('L03 is solvable through the restore-pattern engine', () {
      final l03 = catalog.firstWhere((l) => l.id == 'L03');
      final engine = RestorePatternEngine.fromConfig(l03.config);
      for (final cell in engine.cells) {
        expect(engine.fillCell(cell.id, cell.solutionTileId), isTrue,
            reason: cell.id);
      }
      expect(engine.isComplete, isTrue);
    });

    test('L04 is solvable through the build-order engine', () {
      final l04 = catalog.firstWhere((l) => l.id == 'L04');
      final engine = BuildOrderEngine.fromConfig(l04.config);
      // Correct order: wheels -> bed -> handle.
      for (final partId in ['part_wheels', 'part_bed', 'part_handle']) {
        final result = engine.selectPart(partId);
        expect(result.accepted, isTrue, reason: partId);
      }
      expect(engine.isComplete, isTrue);
    });

    test('puzzle types follow the launch plan', () {
      final expected = {
        'L01': 'matchParts', 'L02': 'matchParts', 'L03': 'restorePattern',
        'L04': 'buildOrder', 'L05': 'buildOrder', 'L06': 'restorePattern',
        'L07': 'matchParts', 'L08': 'matchParts', 'L09': 'buildOrder',
        'L10': 'restorePattern', 'L11': 'matchParts', 'L12': 'buildOrder',
        'L13': 'restorePattern', 'L14': 'matchParts', 'L15': 'buildOrder',
        'L16': 'restorePattern', 'L17': 'matchParts', 'L18': 'buildOrder',
        'L19': 'restorePattern', 'L20': 'finale',
      };
      for (final l in catalog) {
        expect(l.puzzleType, expected[l.id], reason: l.id);
      }
    });

    test('no remote URLs in asset references', () {
      for (final l in catalog) {
        for (final e in l.validate()) {
          expect(e, isNot(contains('remote')));
        }
      }
    });
  });

  group('Level availability and entitlement boundaries', () {
    late List<Level> catalog;
    late Map<String, Level> byId;
    setUpAll(() {
      catalog = loadCatalog();
      byId = {for (final l in catalog) l.id: l};
    });

    bool avail(String id, Set<String> done, bool entitled) =>
        Level.isLevelAvailable(level: byId[id]!, completedLevels: done, entitlementGranted: entitled);

    test('L01 always available, even with nothing completed', () {
      expect(avail('L01', {}, false), isTrue);
    });

    test('L02 needs L01 complete', () {
      expect(avail('L02', {}, false), isFalse);
      expect(avail('L02', {'L01'}, false), isTrue);
    });

    test('chain rule: L10 needs L09 (transitively the chain)', () {
      expect(avail('L10', {'L01'}, false), isFalse);
      expect(avail('L10', {'L01','L02','L03','L04','L05','L06','L07','L08','L09'}, false), isTrue);
    });

    test('L11 pack boundary: needs L10 AND entitlement', () {
      final done = {'L01','L02','L03','L04','L05','L06','L07','L08','L09','L10'};
      expect(avail('L11', done, false), isFalse); // no purchase
      expect(avail('L11', done, true), isTrue);   // purchased
      expect(avail('L11', {'L01'}, true), isFalse); // missing prerequisite
    });

    test('L20 needs L19 and entitlement', () {
      final done = {for (var i = 1; i <= 19; i++) 'L${i.toString().padLeft(2, '0')}'};
      expect(avail('L20', done, false), isFalse);
      expect(avail('L20', done, true), isTrue);
    });

    test('entitlement never grants levels past uncompleted prerequisites', () {
      expect(avail('L15', {'L01'}, true), isFalse);
    });
  });
}
