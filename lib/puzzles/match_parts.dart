/// System A — "Match the parts" puzzle engine (pure Dart, no Flutter).
///
/// The engine is UI-agnostic: it decides correctness and placement state, and
/// the UI performs the snap animation / gentle return to tray.
library;

import 'dart:math';

/// A drop target on the broken object.
class Slot {
  /// Slot id, e.g. "slot_wheel".
  final String id;

  /// Id of the piece this slot accepts.
  final String acceptsPartId;

  /// Proportional position (0.0-1.0) of the slot center.
  final double x;
  final double y;

  /// Orientations (degrees) the accepted piece may have to snap.
  final Set<int> allowedOrientations;

  const Slot({
    required this.id,
    required this.acceptsPartId,
    required this.x,
    required this.y,
    required this.allowedOrientations,
  });
}

/// A draggable piece in the tray.
class Piece {
  /// Piece id, e.g. "part_wheel".
  final String id;

  /// Shape name used by the UI, e.g. "circle".
  final String shape;

  /// Current orientation in degrees (90° steps).
  int orientation;

  /// Whether the child may rotate this piece.
  final bool rotationAllowed;

  /// Distractors match no slot and are always "wrong".
  final bool isDistractor;

  Piece({
    required this.id,
    required this.shape,
    required this.orientation,
    this.rotationAllowed = false,
    this.isDistractor = false,
  });
}

/// Outcome of a placement attempt.
class PlaceResult {
  /// True when the piece snapped into the slot.
  final bool correct;

  /// True when the engine locked input (snap animation should play).
  final bool inputLocked;

  /// Machine-readable reason: 'snapped' | 'wrong_piece' | 'wrong_orientation'
  /// | 'slot_filled' | 'piece_placed' | 'unknown' | 'ignored_locked'.
  final String reason;

  const PlaceResult({
    required this.correct,
    required this.inputLocked,
    required this.reason,
  });
}

/// Engine for the "Match the parts" puzzle system.
///
/// Flow: UI calls [nearestSlot] on drop/tap, then [tryPlace]. A correct
/// placement sets [inputLocked] until the UI calls [unlockInput] after the
/// snap animation. Wrong placements never move the piece — the UI animates a
/// gentle return to the tray.
class MatchPartsEngine {
  /// All drop targets, in authoring order.
  final List<Slot> slots;

  /// All pieces, including distractors.
  final List<Piece> pieces;

  /// Proportional distance within which a drop/tap counts toward a slot.
  final double snapRadius;

  /// slotId -> pieceId for snapped placements.
  final Map<String, String> placed = {};

  /// True while a snap animation is playing; placements are ignored.
  bool inputLocked = false;

  MatchPartsEngine({
    required this.slots,
    required this.pieces,
    required this.snapRadius,
  });

  /// Builds an engine from a level `config` map (see CONTENT_SCHEMA.md).
  factory MatchPartsEngine.fromConfig(Map<String, dynamic> config) {
    final slots = <Slot>[];
    for (final s in (config['slots'] as List? ?? [])) {
      final m = (s as Map).cast<String, dynamic>();
      slots.add(Slot(
        id: (m['id'] ?? '').toString(),
        acceptsPartId: (m['acceptsPartId'] ?? '').toString(),
        x: ((m['x'] as num?) ?? 0).toDouble(),
        y: ((m['y'] as num?) ?? 0).toDouble(),
        allowedOrientations:
            ((m['allowedOrientations'] as List?) ?? const [])
                .map((o) => (o as num).toInt())
                .toSet(),
      ));
    }
    final pieces = <Piece>[];
    for (final p in (config['pieces'] as List? ?? [])) {
      final m = (p as Map).cast<String, dynamic>();
      pieces.add(Piece(
        id: (m['id'] ?? '').toString(),
        shape: (m['shape'] ?? '').toString(),
        orientation: ((m['initialOrientation'] as num?) ?? 0).toInt(),
        rotationAllowed: m['rotationAllowed'] == true,
        isDistractor: m['isDistractor'] == true,
      ));
    }
    return MatchPartsEngine(
      slots: slots,
      pieces: pieces,
      snapRadius: ((config['snapRadius'] as num?) ?? 0.07).toDouble(),
    );
  }

  /// Nearest slot within [snapRadius] of proportional point (x, y), or null.
  Slot? nearestSlot(double x, double y) {
    Slot? best;
    var bestDist = double.infinity;
    for (final slot in slots) {
      final d = sqrt(pow(slot.x - x, 2) + pow(slot.y - y, 2));
      if (d <= snapRadius && d < bestDist) {
        best = slot;
        bestDist = d;
      }
    }
    return best;
  }

  /// Attempts to place [pieceId] into [slotId].
  PlaceResult tryPlace(String pieceId, String slotId) {
    if (inputLocked) {
      return const PlaceResult(
          correct: false, inputLocked: true, reason: 'ignored_locked');
    }
    final piece = _pieceById(pieceId);
    final slot = _slotById(slotId);
    if (piece == null || slot == null) {
      return const PlaceResult(
          correct: false, inputLocked: false, reason: 'unknown');
    }
    if (placed.containsKey(slotId)) {
      return const PlaceResult(
          correct: false, inputLocked: false, reason: 'slot_filled');
    }
    if (placed.containsValue(pieceId)) {
      return const PlaceResult(
          correct: false, inputLocked: false, reason: 'piece_placed');
    }
    if (slot.acceptsPartId != pieceId) {
      return const PlaceResult(
          correct: false, inputLocked: false, reason: 'wrong_piece');
    }
    if (!slot.allowedOrientations.contains(piece.orientation)) {
      // Gentle return: the engine does not move the piece; the UI animates it
      // back to the tray.
      return const PlaceResult(
          correct: false, inputLocked: false, reason: 'wrong_orientation');
    }
    placed[slotId] = pieceId;
    inputLocked = true;
    return const PlaceResult(
        correct: true, inputLocked: true, reason: 'snapped');
  }

  /// Rotates a piece by 90°. Returns false when the piece does not exist or
  /// rotation is not allowed for it.
  bool rotatePiece(String pieceId) {
    final piece = _pieceById(pieceId);
    if (piece == null || !piece.rotationAllowed) return false;
    piece.orientation = (piece.orientation + 90) % 360;
    return true;
  }

  /// Clears the input lock after the snap animation finishes.
  void unlockInput() {
    inputLocked = false;
  }

  /// True when every slot has a snapped piece.
  bool get isComplete => slots.every((s) => placed.containsKey(s.id));

  /// Clears placements and the lock (replay support).
  void reset() {
    placed.clear();
    inputLocked = false;
  }

  Slot? _slotById(String id) {
    for (final s in slots) {
      if (s.id == id) return s;
    }
    return null;
  }

  Piece? _pieceById(String id) {
    for (final p in pieces) {
      if (p.id == id) return p;
    }
    return null;
  }
}
