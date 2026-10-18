import 'package:test/test.dart';
import 'package:tiny_repair_town/puzzles/restore_pattern.dart';

RestorePatternEngine kiteEngine() {
  return RestorePatternEngine(
    rows: 2,
    cols: 2,
    cells: [
      PatternCell(id: 'c00', row: 0, col: 0, solutionTileId: 't_red_star', alternativeTileIds: []),
      PatternCell(id: 'c01', row: 0, col: 1, solutionTileId: 't_blue_dot', alternativeTileIds: []),
      PatternCell(id: 'c10', row: 1, col: 0, solutionTileId: 't_green_stripe', alternativeTileIds: ['t_green_check']),
      PatternCell(id: 'c11', row: 1, col: 1, solutionTileId: 't_yellow_plain', alternativeTileIds: []),
    ],
    tiles: [
      PatternTile(id: 't_red_star', shape: 'star', pattern: 'stripes'),
      PatternTile(id: 't_blue_dot', shape: 'circle', pattern: 'dots'),
      PatternTile(id: 't_green_stripe', shape: 'square', pattern: 'stripes'),
      PatternTile(id: 't_green_check', shape: 'square', pattern: 'check'),
      PatternTile(id: 't_yellow_plain', shape: 'triangle', pattern: 'plain'),
      PatternTile(id: 't_wrong', shape: 'star', pattern: 'dots'),
    ],
  );
}

void main() {
  group('RestorePatternEngine (System C)', () {
    test('filling all cells with solutions completes', () {
      final e = kiteEngine();
      expect(e.fillCell('c00', 't_red_star'), isTrue);
      expect(e.fillCell('c01', 't_blue_dot'), isTrue);
      expect(e.fillCell('c10', 't_green_stripe'), isTrue);
      expect(e.fillCell('c11', 't_yellow_plain'), isTrue);
      expect(e.isComplete, isTrue);
    });

    test('authored alternative solution accepted', () {
      final e = kiteEngine();
      e.fillCell('c00', 't_red_star');
      e.fillCell('c01', 't_blue_dot');
      expect(e.fillCell('c10', 't_green_check'), isTrue); // alternative
      e.fillCell('c11', 't_yellow_plain');
      expect(e.isComplete, isTrue);
    });

    test('wrong tile placed but replaceable without penalty; no completion', () {
      final e = kiteEngine();
      expect(e.fillCell('c00', 't_wrong'), isFalse);
      expect(e.filled['c00'], 't_wrong'); // placed, flagged wrong
      expect(e.isCellCorrect('c00'), isFalse);
      expect(e.isComplete, isFalse);
      // replace freely — no penalty, no reset of other cells
      e.fillCell('c01', 't_blue_dot');
      expect(e.fillCell('c00', 't_red_star'), isTrue);
      expect(e.isCellCorrect('c01'), isTrue);
      expect(e.isComplete, isFalse); // still missing c10, c11
    });

    test('completion only when actual conditions satisfied', () {
      final e = kiteEngine();
      e.fillCell('c00', 't_red_star');
      e.fillCell('c01', 't_blue_dot');
      e.fillCell('c10', 't_wrong');
      e.fillCell('c11', 't_yellow_plain');
      expect(e.isComplete, isFalse);
      expect(e.isCellCorrect('c10'), isFalse);
    });

    test('clearCell empties a cell', () {
      final e = kiteEngine();
      e.fillCell('c00', 't_red_star');
      e.clearCell('c00');
      expect(e.filled.containsKey('c00'), isFalse);
      expect(e.isCellCorrect('c00'), isFalse);
    });

    test('unknown cell or tile handled without crash', () {
      final e = kiteEngine();
      expect(e.fillCell('nope', 't_red_star'), isFalse);
      expect(e.isCellCorrect('nope'), isFalse);
    });

    test('tiles carry shape+pattern markings, not color alone', () {
      final e = kiteEngine();
      final t = e.tiles.firstWhere((t) => t.id == 't_red_star');
      expect(t.shape, isNotEmpty);
      expect(t.pattern, isNotEmpty);
    });

    test('reset clears for replay', () {
      final e = kiteEngine();
      e.fillCell('c00', 't_red_star');
      e.reset();
      expect(e.filled, isEmpty);
      expect(e.isComplete, isFalse);
    });
  });
}
