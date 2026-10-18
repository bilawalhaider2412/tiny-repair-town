/// System A — "Match the parts" screen (L01 in Stage 3).
///
/// Drag AND tap-to-place (tap piece, then tap slot). Correct placements snap
/// with the engine input lock held until the animation ends (unlockInput
/// after). Wrong placements never move the piece — it stays in the tray and a
/// gentle message appears. Unlimited attempts, 3 free hint strengths.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';
import 'package:tiny_repair_town/models/level.dart';
import 'package:tiny_repair_town/puzzles/match_parts.dart';

import '../../app_state.dart';
import '../../app_theme.dart';
import '../../audio.dart';
import '../../widgets/inactivity_pulse.dart';
import '../../widgets/pause_dialog.dart';
import '../../widgets/tile_art.dart';
import '../../widgets/tutorial_overlay.dart';

class MatchPartsScreen extends StatefulWidget {
  final AppState appState;
  final Level level;
  final Map<String, dynamic> raw;

  const MatchPartsScreen({
    super.key,
    required this.appState,
    required this.level,
    required this.raw,
  });

  @override
  State<MatchPartsScreen> createState() => _MatchPartsScreenState();
}

class _MatchPartsScreenState extends State<MatchPartsScreen> {
  late MatchPartsEngine _engine;
  final GlobalKey _workAreaKey = GlobalKey();

  String? _selectedPieceId; // tap-to-place selection
  String? _feedbackKey; // localization key for the gentle feedback line
  int _hintLevel = 0; // 0 = none, 1..3 strengths
  String? _hintPieceId;
  String? _hintSlotId;
  bool _showTutorial = false;
  bool _showPause = false;
  bool _completed = false;
  final Set<String> _snapping = {}; // pieceIds mid snap-animation
  late InactivityPulse _pulse; // spec §9: hint button pulses once after ~10s idle

  AppState get _app => widget.appState;
  String get _lang => _app.lang;
  bool get _reducedMotion => _app.reducedMotion;

  @override
  void initState() {
    super.initState();
    _engine = MatchPartsEngine.fromConfig(widget.level.config);
    _restoreCheckpoint();
    _showTutorial =
        widget.level.tutorial && !_app.tutorialSeen(widget.level.id);
    // Inactivity pulse: never fires while the tutorial/pause menu is open,
    // an animation blocks input, audio is playing, or the app is backgrounded
    // (backgrounding opens the pause overlay, which pauses the pulse).
    _pulse = InactivityPulse(
      isSuppressed: () =>
          _showTutorial ||
          _showPause ||
          _completed ||
          _engine.inputLocked ||
          _snapping.isNotEmpty ||
          AudioService.instance.isPlaying,
    );
    if (!_showTutorial) _pulse.start();
    // Save a checkpoint at level start (stable boundary).
    _saveCheckpoint();
    _app.onBackgroundPause = _pauseFromBackground;
  }

  @override
  void dispose() {
    _pulse.dispose();
    if (_app.onBackgroundPause == _pauseFromBackground) {
      _app.onBackgroundPause = null;
    }
    super.dispose();
  }

  // --- Checkpoint ----------------------------------------------------------

  void _restoreCheckpoint() {
    final cp = _app.checkpointFor(widget.level.id);
    final placed = cp?['placed'];
    if (placed is Map) {
      for (final e in placed.entries) {
        _engine.tryPlace(e.value.toString(), e.key.toString());
        _engine.unlockInput();
      }
    }
  }

  Future<void> _saveCheckpoint() => _app.saveCheckpoint(widget.level.id, {
        'engine': 'matchParts',
        'placed': Map<String, String>.of(_engine.placed),
      });

  // --- Input ---------------------------------------------------------------

  void _attemptPlace(String pieceId, String slotId) {
    if (_engine.inputLocked || _completed) return;
    final result = _engine.tryPlace(pieceId, slotId);
    if (result.correct) {
      setState(() {
        _snapping.add(pieceId);
        _selectedPieceId = null;
        _feedbackKey = 'thatFits';
        _hintLevel = 0;
        _hintPieceId = null;
        _hintSlotId = null;
      });
      final ms = _reducedMotion ? 0 : 320;
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _engine.unlockInput();
        setState(() => _snapping.remove(pieceId));
        _saveCheckpoint();
        if (_engine.isComplete) _onComplete();
      });
    } else {
      setState(() {
        // Gentle handling: the piece never moves; the child tries again.
        _feedbackKey =
            result.reason == 'wrong_piece' || result.reason == 'wrong_orientation'
                ? 'tryAnotherPiece'
                : 'tryAgain';
        // Keep the tap selection so another slot can be tried immediately.
      });
    }
  }

  /// Tap-to-place on a slot: nearest slot to the tap point.
  void _onSlotTap(Slot slot) {
    final sel = _selectedPieceId;
    if (sel == null) return;
    _attemptPlace(sel, slot.id);
  }

  void _onPieceTap(String pieceId) {
    if (_engine.inputLocked || _completed) return;
    if (_engine.placed.containsValue(pieceId)) return; // already snapped
    setState(() {
      _selectedPieceId = _selectedPieceId == pieceId ? null : pieceId;
    });
  }

  void _onDragAccept(DragTargetDetails<String> details) {
    final box =
        _workAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final local = box.globalToLocal(details.offset);
    final px = (local.dx / box.size.width).clamp(0.0, 1.0);
    final py = (local.dy / box.size.height).clamp(0.0, 1.0);
    final slot = _engine.nearestSlot(px, py);
    if (slot == null) {
      // Dropped outside any slot: gentle return to tray (Draggable does it).
      setState(() => _feedbackKey = 'tryAnotherPiece');
      return;
    }
    _attemptPlace(details.data, slot.id);
  }

  // --- Hints -----------------------------------------------------------------

  void _onHint() {
    if (_completed) return;
    _pulse.reset(); // explicit interaction restarts the inactivity window
    setState(() {
      _hintLevel = _hintLevel >= 3 ? 0 : _hintLevel + 1;
      _hintPieceId = null;
      _hintSlotId = null;
      if (_hintLevel >= 1) {
        // First unplaced slot's piece: the "useful piece".
        for (final slot in _engine.slots) {
          if (!_engine.placed.containsKey(slot.id)) {
            _hintPieceId = slot.acceptsPartId;
            if (_hintLevel >= 2) _hintSlotId = slot.id;
            break;
          }
        }
      }
    });
    if (_hintLevel == 3 && _hintPieceId != null && _hintSlotId != null) {
      // Strength 3: demonstrate one correct action, then return control.
      Future.delayed(Duration(milliseconds: _reducedMotion ? 50 : 600), () {
        if (!mounted || _completed) return;
        _attemptPlace(_hintPieceId!, _hintSlotId!);
      });
    }
  }

  // --- Completion / pause / back ----------------------------------------------

  Future<void> _onComplete() async {
    if (_completed) return;
    setState(() => _completed = true);
    await _app.completeLevel(widget.level); // idempotent sticker award
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      '/celebration',
      arguments: widget.level.id,
    );
  }

  void _pauseFromBackground() {
    if (!mounted || _completed) return;
    _pulse.pause();
    _saveCheckpoint();
    if (!_showPause) setState(() => _showPause = true);
  }

  Future<void> _onBack() async {
    if (_showTutorial) {
      _dismissTutorial();
      return;
    }
    if (_showPause) {
      setState(() => _showPause = false);
      _pulse.reset();
      return;
    }
    _pulse.pause();
    await _saveCheckpoint();
    if (mounted) setState(() => _showPause = true);
  }

  void _dismissTutorial() {
    setState(() => _showTutorial = false);
    _pulse.reset();
    _app.markTutorialSeen(widget.level.id);
  }

  // --- Build -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('level_back'),
            icon: const Icon(Icons.arrow_back, size: 32),
            onPressed: _onBack,
            tooltip: tr('backToTown', _lang),
          ),
          title: Text(level.title[_lang] ?? level.title['en'] ?? ''),
          actions: [
            PulsingHintButton(
              buttonKey: const Key('hint_button'),
              pulseSignal: _pulse.signal,
              reducedMotion: _reducedMotion,
              onPressed: _onHint,
              tooltip: tr('hint', _lang),
            ),
          ],
        ),
        body: Listener(
          // Any interaction restarts the inactivity window (spec §9).
          onPointerDown: (_) => _pulse.reset(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _RequestBanner(
                        text: level.request[_lang] ?? level.request['en'] ?? '',
                        requester: level.requester),
                    Expanded(child: _buildWorkArea()),
                    _FeedbackLine(feedbackKey: _feedbackKey, lang: _lang),
                    _buildTray(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_showTutorial)
                TutorialOverlay(
                  appState: _app,
                  script: _tutorialScript(),
                  onDone: _dismissTutorial,
                ),
              if (_showPause)
                PauseDialog(
                  appState: _app,
                  onResume: () {
                    setState(() => _showPause = false);
                    _pulse.reset();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _tutorialScript() {
    final raw = widget.raw['tutorialScript'];
    if (raw is Map) {
      final list = raw[_lang] ?? raw['en'];
      if (list is List) return list.map((e) => e.toString()).toList();
    }
    return [tr('dragOrTap', _lang)];
  }

  Widget _buildWorkArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Slots must never overlap: size them from the smallest pairwise
        // slot distance (spec §5: generous hit areas, no tiny targets).
        var minDist = double.infinity;
        final slots = _engine.slots;
        for (var i = 0; i < slots.length; i++) {
          for (var j = i + 1; j < slots.length; j++) {
            final dx = (slots[i].x - slots[j].x) * w;
            final dy = (slots[i].y - slots[j].y) * h;
            final d = math.sqrt(dx * dx + dy * dy);
            if (d < minDist) minDist = d;
          }
        }
        minDist = minDist == double.infinity ? 120.0 : minDist;
        final slotSize = (minDist * 0.8).clamp(56.0, 140.0);
        return Container(
          key: _workAreaKey,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TownTheme.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: TownTheme.blue, width: 3),
          ),
          child: Stack(
            children: [
              // Broken-object placeholder art (development asset).
              Center(
                child: Opacity(
                  opacity: 0.25,
                  child: Icon(
                    Icons.directions_car,
                    size: w * 0.5,
                    color: TownTheme.blue,
                  ),
                ),
              ),
              for (final slot in _engine.slots)
                Positioned(
                  left: slot.x * w - slotSize / 2,
                  top: slot.y * h - slotSize / 2,
                  width: slotSize,
                  height: slotSize,
                  child: _buildSlot(slot),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlot(Slot slot) {
    final placedPieceId = _engine.placed[slot.id];
    final isHinted = _hintSlotId == slot.id;
    Widget content;
    if (placedPieceId != null) {
      final piece = _engine.pieces.firstWhere((p) => p.id == placedPieceId);
      final snapping = _snapping.contains(placedPieceId);
      content = AnimatedScale(
        scale: snapping ? 0.6 : 1.0,
        duration: Duration(milliseconds: _reducedMotion ? 0 : 300),
        curve: Curves.easeOutBack,
        child: _PieceArt(piece: piece, size: 64),
      );
    } else {
      content = SlotOutline(
          shapeHint: _shapeHintFor(slot) ?? 'circle');
    }
    return DragTarget<String>(
      onAcceptWithDetails: _onDragAccept,
      builder: (context, candidate, rejected) => GestureDetector(
        key: Key('slot_${slot.id}'),
        onTap: () => _onSlotTap(slot),
        child: Semantics(
          label: '${tr('slotSemantic', _lang)} ${slot.id}',
          button: true,
          child: Container(
            decoration: isHinted
                ? BoxDecoration(
                    border: Border.all(color: TownTheme.yellow, width: 6),
                    borderRadius: BorderRadius.circular(16),
                  )
                : null,
            child: content,
          ),
        ),
      ),
    );
  }

  String? _shapeHintFor(Slot slot) {
    final raw = widget.raw['config'];
    if (raw is Map) {
      final slots = raw['slots'];
      if (slots is List) {
        for (final s in slots) {
          if (s is Map && s['id'] == slot.id) {
            return s['shapeHint']?.toString();
          }
        }
      }
    }
    return null;
  }

  Widget _buildTray() {
    final trayPieces = _engine.pieces
        .where((p) => !_engine.placed.containsValue(p.id))
        .toList();
    // Extra guidance: persistently highlight the useful piece — the same
    // nudge a level-1 hint gives, without consuming the hint button.
    final guidancePieceId = _guidancePieceId();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TownTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TownTheme.green, width: 3),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [for (final piece in trayPieces) _buildPiece(piece, guidancePieceId)],
      ),
    );
  }

  /// Piece id the extra-guidance highlight should mark, or null.
  String? _guidancePieceId() {
    if (!_app.extraGuidance || _hintLevel != 0 || _completed) return null;
    for (final slot in _engine.slots) {
      if (!_engine.placed.containsKey(slot.id)) return slot.acceptsPartId;
    }
    return null;
  }

  Widget _buildPiece(Piece piece, String? guidancePieceId) {
    final selected = _selectedPieceId == piece.id;
    final hinted =
        _hintPieceId == piece.id || guidancePieceId == piece.id;
    final art = _PieceArt(piece: piece, size: 64);
    final labeled = Semantics(
      label: _pieceLabel(piece),
      button: true,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: selected ? TownTheme.yellow : TownTheme.cream,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hinted
                ? TownTheme.yellow
                : (selected ? TownTheme.coral : TownTheme.blue),
            width: hinted || selected ? 5 : 2,
          ),
        ),
        child: Center(child: art),
      ),
    );
    return Draggable<String>(
      data: piece.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.85, child: art),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: labeled),
      child: GestureDetector(
        key: Key('piece_${piece.id}'),
        onTap: () => _onPieceTap(piece.id),
        child: labeled,
      ),
    );
  }

  String _pieceLabel(Piece piece) {
    final raw = widget.raw['config'];
    if (raw is Map) {
      final pieces = raw['pieces'];
      if (pieces is List) {
        for (final p in pieces) {
          if (p is Map && p['id'] == piece.id) {
            final label = p['label'];
            if (label is Map) {
              return (label[_lang] ?? label['en'] ?? piece.id).toString();
            }
          }
        }
      }
    }
    return piece.id;
  }
}

class _PieceArt extends StatelessWidget {
  final Piece piece;
  final double size;
  const _PieceArt({required this.piece, required this.size});

  @override
  Widget build(BuildContext context) =>
      TileArt(shape: piece.shape, pattern: 'plain', size: size);
}

class _RequestBanner extends StatelessWidget {
  final String text;
  final String requester;
  const _RequestBanner({required this.text, required this.requester});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TownTheme.yellow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: TownTheme.coral,
            child: Icon(Icons.person, color: TownTheme.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _FeedbackLine extends StatelessWidget {
  final String? feedbackKey;
  final String lang;
  const _FeedbackLine({required this.feedbackKey, required this.lang});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Center(
        child: Text(
          feedbackKey == null ? '' : tr(feedbackKey!, lang),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: TownTheme.green),
        ),
      ),
    );
  }
}

