/// System C — "Restore the pattern" screen (L03 in Stage 3).
///
/// The reference is always visible (never a memory test). Tap a tile, then tap
/// a cell — or drag the tile onto the cell. engine.fillCell replaces freely
/// without penalty; completion fires only when the actual conditions hold.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';
import 'package:tiny_repair_town/models/level.dart';
import 'package:tiny_repair_town/puzzles/restore_pattern.dart';

import '../../app_state.dart';
import '../../app_theme.dart';
import '../../audio.dart';
import '../../widgets/inactivity_pulse.dart';
import '../../widgets/pause_dialog.dart';
import '../../widgets/tile_art.dart';
import '../../widgets/tutorial_overlay.dart';

class RestorePatternScreen extends StatefulWidget {
  final AppState appState;
  final Level level;
  final Map<String, dynamic> raw;

  const RestorePatternScreen({
    super.key,
    required this.appState,
    required this.level,
    required this.raw,
  });

  @override
  State<RestorePatternScreen> createState() => _RestorePatternScreenState();
}

class _RestorePatternScreenState extends State<RestorePatternScreen> {
  late RestorePatternEngine _engine;
  String? _selectedTileId;
  int _hintLevel = 0;
  String? _hintTileId;
  String? _hintCellId;
  String? _feedbackKey;
  bool _showTutorial = false;
  bool _showPause = false;
  bool _completed = false;
  late InactivityPulse _pulse; // spec §9: hint button pulses once after ~10s idle

  AppState get _app => widget.appState;
  String get _lang => _app.lang;

  @override
  void initState() {
    super.initState();
    _engine = RestorePatternEngine.fromConfig(widget.level.config);
    final cp = _app.checkpointFor(widget.level.id);
    final filled = cp?['filled'];
    if (filled is Map) {
      for (final e in filled.entries) {
        _engine.fillCell(e.key.toString(), e.value.toString());
      }
    }
    _showTutorial =
        widget.level.tutorial && !_app.tutorialSeen(widget.level.id);
    // Inactivity pulse: deferred while a menu is open, the app is
    // backgrounded (opens the pause overlay), or audio is playing.
    // (This system has no input-blocking animations.)
    _pulse = InactivityPulse(
      isSuppressed: () =>
          _showTutorial ||
          _showPause ||
          _completed ||
          AudioService.instance.isPlaying,
    );
    if (!_showTutorial) _pulse.start();
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

  Future<void> _saveCheckpoint() => _app.saveCheckpoint(widget.level.id, {
        'engine': 'restorePattern',
        'filled': Map<String, String>.of(_engine.filled),
      });

  /// Tile id the extra-guidance highlight should mark, or null.
  String? _guidanceTileId() {
    if (!_app.extraGuidance || _hintLevel != 0 || _completed) return null;
    for (final cell in _engine.cells) {
      if (!_engine.isCellCorrect(cell.id)) return cell.solutionTileId;
    }
    return null;
  }

  void _fillCell(String cellId, String tileId) {
    if (_completed) return;
    final accepted = _engine.fillCell(cellId, tileId);
    setState(() {
      // Wrong tiles stay placed and can be replaced freely — no penalty,
      // just a gentle note. Correct ones get a happy confirmation.
      _feedbackKey = accepted ? 'thatFits' : 'tryAnotherPiece';
      _hintLevel = 0;
      _hintTileId = null;
      _hintCellId = null;
      if (accepted) _selectedTileId = null;
    });
    _saveCheckpoint();
    if (_engine.isComplete) _onComplete();
  }

  void _onTileTap(String tileId) {
    if (_completed) return;
    setState(() {
      _selectedTileId = _selectedTileId == tileId ? null : tileId;
    });
  }

  void _onCellTap(String cellId) {
    final sel = _selectedTileId;
    if (sel == null || _completed) return;
    _fillCell(cellId, sel);
  }

  void _onHint() {
    if (_completed) return;
    _pulse.reset(); // explicit interaction restarts the inactivity window
    setState(() {
      _hintLevel = _hintLevel >= 3 ? 0 : _hintLevel + 1;
      _hintTileId = null;
      _hintCellId = null;
      if (_hintLevel >= 1) {
        // First cell that does not yet hold an accepted tile.
        for (final cell in _engine.cells) {
          if (!_engine.isCellCorrect(cell.id)) {
            _hintTileId = cell.solutionTileId;
            if (_hintLevel >= 2) _hintCellId = cell.id;
            break;
          }
        }
      }
    });
    if (_hintLevel == 3 && _hintTileId != null && _hintCellId != null) {
      Future.delayed(
          Duration(milliseconds: _app.reducedMotion ? 50 : 700), () {
        if (!mounted || _completed) return;
        _fillCell(_hintCellId!, _hintTileId!);
      });
    }
  }

  Future<void> _onComplete() async {
    if (_completed) return;
    setState(() => _completed = true);
    await _app.completeLevel(widget.level);
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

  List<String> _tutorialScript() {
    final raw = widget.raw['tutorialScript'];
    if (raw is Map) {
      final list = raw[_lang] ?? raw['en'];
      if (list is List) return list.map((e) => e.toString()).toList();
    }
    return [tr('choosePiece', _lang)];
  }

  String _tileLabel(String tileId) {
    final config = widget.raw['config'];
    if (config is Map) {
      final tiles = config['tiles'];
      if (tiles is List) {
        for (final t in tiles) {
          if (t is Map && t['id'] == tileId) {
            final label = t['label'];
            if (label is Map) {
              return (label[_lang] ?? label['en'] ?? tileId).toString();
            }
          }
        }
      }
    }
    return tileId;
  }

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
              reducedMotion: _app.reducedMotion,
              onPressed: _onHint,
              tooltip: tr('hint', _lang),
            ),
          ],
        ),
        body: Listener(
          onPointerDown: (_) => _pulse.reset(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _ReferenceStrip(engine: _engine, labelOf: _tileLabel),
                    const SizedBox(height: 8),
                    Expanded(child: _buildGrid()),
                    SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          _feedbackKey == null ? '' : tr(_feedbackKey!, _lang),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: TownTheme.green),
                        ),
                      ),
                    ),
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

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _engine.cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _engine.cells.length,
      itemBuilder: (context, i) {
        final cell = _engine.cells[i];
        final filledTileId = _engine.filled[cell.id];
        final hinted = _hintCellId == cell.id;
        final correct =
            filledTileId != null && _engine.isCellCorrect(cell.id);
        return DragTarget<String>(
          onAcceptWithDetails: (details) =>
              _fillCell(cell.id, details.data),
          builder: (context, candidate, rejected) => GestureDetector(
            key: Key('cell_${cell.id}'),
            onTap: () => _onCellTap(cell.id),
            child: Semantics(
              label:
                  '${tr('panelSemantic', _lang)} ${cell.row + 1}-${cell.col + 1}',
              button: true,
              child: Container(
                decoration: BoxDecoration(
                  color: correct
                      ? TownTheme.green.withValues(alpha: 0.35)
                      : TownTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hinted ? TownTheme.yellow : TownTheme.blue,
                    width: hinted ? 6 : 3,
                  ),
                ),
                child: Center(
                  child: filledTileId == null
                      ? const Text('?',
                          style: TextStyle(
                              fontSize: 32, color: TownTheme.blue))
                      : _tileArt(filledTileId, 56),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tileArt(String tileId, double size) {
    final tile =
        _engine.tiles.firstWhere((t) => t.id == tileId, orElse: () => PatternTile(id: tileId, shape: 'circle', pattern: 'plain'));
    return TileArt(shape: tile.shape, pattern: tile.pattern, size: size);
  }

  Widget _buildTray() {
    // Extra guidance: persistently highlight the useful tile — the same
    // nudge a level-1 hint gives, without consuming the hint button.
    final guidanceTileId = _guidanceTileId();
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
        children: [
          for (final tile in _engine.tiles)
            _TrayTile(
              key: Key('tile_${tile.id}'),
              tile: tile,
              label: _tileLabel(tile.id),
              selected: _selectedTileId == tile.id,
              hinted: _hintTileId == tile.id || guidanceTileId == tile.id,
              onTap: () => _onTileTap(tile.id),
            ),
        ],
      ),
    );
  }
}

/// Always-visible reference strip (spec §7: never a memory test).
class _ReferenceStrip extends StatelessWidget {
  final RestorePatternEngine engine;
  final String Function(String) labelOf;

  const _ReferenceStrip({required this.engine, required this.labelOf});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TownTheme.yellow.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TownTheme.coral, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final cell in engine.cells)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _ReferencePanel(cell: cell, engine: engine),
            ),
        ],
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  final PatternCell cell;
  final RestorePatternEngine engine;

  const _ReferencePanel({required this.cell, required this.engine});

  @override
  Widget build(BuildContext context) {
    final tile = engine.tiles.firstWhere(
        (t) => t.id == cell.solutionTileId,
        orElse: () =>
            PatternTile(id: cell.solutionTileId, shape: 'circle', pattern: 'plain'));
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: TownTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TownTheme.ink, width: 2),
      ),
      child: Center(
          child: TileArt(shape: tile.shape, pattern: tile.pattern, size: 44)),
    );
  }
}

class _TrayTile extends StatelessWidget {
  final PatternTile tile;
  final String label;
  final bool selected;
  final bool hinted;
  final VoidCallback onTap;

  const _TrayTile({
    super.key,
    required this.tile,
    required this.label,
    required this.selected,
    required this.hinted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      label: label,
      button: true,
      child: Container(
        width: 84,
        height: 84,
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
        child: Center(
            child: TileArt(
                shape: tile.shape, pattern: tile.pattern, size: 60)),
      ),
    );
    return Draggable<String>(
      data: tile.id,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: TileArt(
              shape: tile.shape, pattern: tile.pattern, size: 60),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}
