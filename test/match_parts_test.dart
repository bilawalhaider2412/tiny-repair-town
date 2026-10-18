import 'package:test/test.dart';
import 'package:tiny_repair_town/puzzles/match_parts.dart';

MatchPartsEngine l01Engine() {
  return MatchPartsEngine(
    slots: [
      Slot(id: 'slot_wheel', acceptsPartId: 'part_wheel', x: 0.28, y: 0.68, allowedOrientations: {0}),
      Slot(id: 'slot_window', acceptsPartId: 'part_window', x: 0.55, y: 0.42, allowedOrientations: {0}),
      Slot(id: 'slot_roof', acceptsPartId: 'part_roof', x: 0.55, y: 0.22, allowedOrientations: {0}),
    ],
    pieces: [
      Piece(id: 'part_wheel', shape: 'circle', orientation: 0),
      Piece(id: 'part_window', shape: 'rounded_square', orientation: 0),
      Piece(id: 'part_roof', shape: 'triangle', orientation: 0),
    ],
    snapRadius: 0.09,
  );
}

void main() {
  group('MatchPartsEngine (System A)', () {
    test('correct part snaps and locks input until animation done', () {
      final e = l01Engine();
      final r = e.tryPlace('part_wheel', 'slot_wheel');
      expect(r.correct, isTrue);
      expect(r.reason, 'snapped');
      expect(e.inputLocked, isTrue);
      expect(e.placed['slot_wheel'], 'part_wheel');
      // input ignored while locked
      final r2 = e.tryPlace('part_window', 'slot_window');
      expect(r2.correct, isFalse);
      expect(r2.reason, 'ignored_locked');
      e.unlockInput();
      final r3 = e.tryPlace('part_window', 'slot_window');
      expect(r3.correct, isTrue);
    });

    test('wrong part returns gently, no state change', () {
      final e = l01Engine();
      final r = e.tryPlace('part_roof', 'slot_wheel');
      expect(r.correct, isFalse);
      expect(r.reason, 'wrong_piece');
      expect(e.inputLocked, isFalse);
      expect(e.placed, isEmpty);
      expect(e.isComplete, isFalse);
    });

    test('matching is by part id, not color/shape alone', () {
      final e = MatchPartsEngine(
        slots: [Slot(id: 's1', acceptsPartId: 'p_red', x: 0.5, y: 0.5, allowedOrientations: {0})],
        pieces: [
          Piece(id: 'p_red', shape: 'circle', orientation: 0),
          Piece(id: 'p_blue', shape: 'circle', orientation: 0), // same shape, wrong id
        ],
        snapRadius: 0.09,
      );
      final r = e.tryPlace('p_blue', 's1');
      expect(r.correct, isFalse);
      expect(r.reason, 'wrong_piece');
    });

    test('orientation must be allowed', () {
      final e = MatchPartsEngine(
        slots: [Slot(id: 's1', acceptsPartId: 'p1', x: 0.5, y: 0.5, allowedOrientations: {90})],
        pieces: [Piece(id: 'p1', shape: 'rect', orientation: 0, rotationAllowed: true)],
        snapRadius: 0.09,
      );
      expect(e.tryPlace('p1', 's1').reason, 'wrong_orientation');
      expect(e.rotatePiece('p1'), isTrue);
      e.unlockInput();
      final r = e.tryPlace('p1', 's1');
      expect(r.correct, isTrue);
    });

    test('rotation only when allowed; 90-degree steps', () {
      final e = l01Engine();
      expect(e.rotatePiece('part_wheel'), isFalse); // L01: no rotation
      final e2 = MatchPartsEngine(
        slots: [Slot(id: 's1', acceptsPartId: 'p1', x: 0.5, y: 0.5, allowedOrientations: {0, 90, 180, 270})],
        pieces: [Piece(id: 'p1', shape: 'rect', orientation: 0, rotationAllowed: true)],
        snapRadius: 0.09,
      );
      expect(e2.rotatePiece('p1'), isTrue);
      expect(e2.pieces.firstWhere((p) => p.id == 'p1').orientation, 90);
    });

    test('one piece cannot fill two slots; filled slot rejects', () {
      final e = l01Engine();
      e.tryPlace('part_wheel', 'slot_wheel');
      e.unlockInput();
      final r = e.tryPlace('part_wheel', 'slot_window');
      expect(r.correct, isFalse);
      expect(r.reason, 'piece_placed');
      final r2 = e.tryPlace('part_window', 'slot_wheel');
      expect(r2.reason, 'slot_filled');
    });

    test('distractor piece matches nothing', () {
      final e = MatchPartsEngine(
        slots: [Slot(id: 's1', acceptsPartId: 'p1', x: 0.5, y: 0.5, allowedOrientations: {0})],
        pieces: [
          Piece(id: 'p1', shape: 'circle', orientation: 0),
          Piece(id: 'decoy', shape: 'star', orientation: 0, isDistractor: true),
        ],
        snapRadius: 0.09,
      );
      expect(e.tryPlace('decoy', 's1').reason, 'wrong_piece');
      e.unlockInput();
      expect(e.tryPlace('p1', 's1').correct, isTrue);
      expect(e.isComplete, isTrue);
    });

    test('nearestSlot respects snap radius', () {
      final e = l01Engine();
      expect(e.nearestSlot(0.28, 0.68)?.id, 'slot_wheel');
      expect(e.nearestSlot(0.05, 0.05), isNull); // too far from any slot
    });

    test('unknown ids handled without crash', () {
      final e = l01Engine();
      expect(e.tryPlace('nope', 'slot_wheel').reason, 'unknown');
      expect(e.tryPlace('part_wheel', 'nope').reason, 'unknown');
    });

    test('reset clears placements for replay', () {
      final e = l01Engine();
      e.tryPlace('part_wheel', 'slot_wheel');
      e.reset();
      expect(e.placed, isEmpty);
      expect(e.inputLocked, isFalse);
      expect(e.isComplete, isFalse);
    });
  });
}
