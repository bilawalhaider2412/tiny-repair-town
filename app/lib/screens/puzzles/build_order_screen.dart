/// System B — "Build in order" screen (L04 in Stage 3).
///
/// Illustrated step guide with the current step highlighted. The child taps
/// parts via engine.selectPart. A wrong selection shows a helpful visual cue
/// and never resets progress. Completed steps stay visible.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';
import 'package:tiny_repair_town/models/level.dart';
import 'package:tiny_repair_town/puzzles/build_order.dart';

import '../../app_state.dart';
import '../../app_theme.dart';
import '../../audio.dart';
import '../../widgets/inactivity_pulse.dart';
import '../../widgets/pause_dialog.dart';
import '../../widgets/tutorial_overlay.dart';

class BuildOrderScreen extends StatefulWidget {
  final AppState appState;
  final Level level;
  final Map<String, dynamic> raw;

  const BuildOrderScreen({
    super.key,
    required this.appState,
    required this.level,
    required this.raw,
  });

  @override
  State<BuildOrderScreen> createState() => _BuildOrderScreenState();
}

class _BuildOrderScreenState extends State<BuildOrderScreen> {
  late BuildOrderEngine _engine;
  int _hintLevel = 0;
  String? _hintStepId;
  String? _feedbackKey;
  bool _showTutorial = false;
  bool _showPause = false;
  bool _completed = false;
  String? _wrongFlashPartId; // brief highlight on a wrong tap
  late InactivityPulse _pulse; // spec §9: hint button pulses once after ~10s idle

  AppState get _app => widget.appState;
  String get _lang => _app.lang;

  @override
  void initState() {
    super.initState();
    _engine = BuildOrderEngine.fromConfig(widget.level.config);
    final cp = _app.checkpointFor(widget.level.id);
    final done = cp?['completedSteps'];
    if (done is List) {
      for (final id in done) {
        _engine.completedStepIds.add(id.toString());
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
        'engine': 'buildOrder',
        'completedSteps': _engine.completedStepIds.toList(),
      });

  void _selectPart(String partId) {
    if (_completed) return;
    final result = _engine.selectPart(partId);
    if (result.accepted) {
      setState(() {
        _feedbackKey = 'thatFits';
        _hintLevel = 0;
        _hintStepId = null;
      });
      _saveCheckpoint();
      if (_engine.isComplete) _onComplete();
    } else {
      // Gentle visual cue: flash the tapped part and highlight the guide's
      // current step. Progress is never reset.
      setState(() {
        _wrongFlashPartId = partId;
        _feedbackKey = 'tryAnotherPiece';
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _wrongFlashPartId = null);
      });
    }
  }

  void _onHint() {
    if (_completed) return;
    _pulse.reset(); // explicit interaction restarts the inactivity window
    setState(() {
      _hintLevel = _hintLevel >= 3 ? 0 : _hintLevel + 1;
      _hintStepId = null;
      final available = _engine.availableSteps;
      if (_hintLevel >= 1 && available.isNotEmpty) {
        _hintStepId = available.first.id; // 1: highlight next step
      }
    });
    if (_hintLevel == 3) {
      // Demonstrate one correct action, then return control.
      final available = _engine.availableSteps;
      if (available.isNotEmpty) {
        Future.delayed(
            Duration(milliseconds: _app.reducedMotion ? 50 : 700), () {
          if (!mounted || _completed) return;
          _selectPart(available.first.partId);
        });
      }
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
                    _RequestBanner(
                        text:
                            level.request[_lang] ?? level.request['en'] ?? ''),
                    const SizedBox(height: 8),
                    Expanded(child: _buildStepGuide()),
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
                    _buildPartTray(),
                    const SizedBox(height: 12),
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

  /// Step guide. Available steps are always highlighted (not colour-only:
  /// yellow fill + coral border + a "choose" cue), which is this system's
  /// extra-guidance support — no separate toggle behaviour needed.
  Widget _buildStepGuide() {
    final availableIds = _engine.availableSteps.map((s) => s.id).toSet();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _engine.steps.length,
      itemBuilder: (context, i) {
        final step = _engine.steps[i];
        final done = _engine.completedStepIds.contains(step.id);
        final current = availableIds.contains(step.id);
        final hinted = _hintStepId == step.id;
        return Card(
          key: Key('step_${step.id}'),
          color: done
              ? TownTheme.green.withValues(alpha: 0.35)
              : (current || hinted
                  ? TownTheme.yellow.withValues(alpha: 0.6)
                  : TownTheme.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: current || hinted ? TownTheme.coral : Colors.transparent,
              width: 4,
            ),
          ),
          child: ListTile(
            minVerticalPadding: 12,
            leading: CircleAvatar(
              backgroundColor: done ? TownTheme.green : TownTheme.blue,
              child: done
                  ? const Icon(Icons.check, color: TownTheme.white)
                  : Text('${i + 1}',
                      style: const TextStyle(
                          color: TownTheme.white,
                          fontWeight: FontWeight.bold)),
            ),
            title: Text(
              _lang == 'ur' ? step.labelUr : step.labelEn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: current
                ? Text(tr('choosePiece', _lang))
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPartTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final step in _engine.steps)
            _PartButton(
              key: Key('part_${step.partId}'),
              label: _lang == 'ur' ? step.labelUr : step.labelEn,
              done: _engine.completedStepIds.contains(step.id),
              wrongFlash: _wrongFlashPartId == step.partId,
              hinted: _hintStepId != null &&
                  _engine.availableSteps.any((s) =>
                      s.id == _hintStepId && s.partId == step.partId),
              onTap: () => _selectPart(step.partId),
            ),
        ],
      ),
    );
  }
}

class _PartButton extends StatelessWidget {
  final String label;
  final bool done;
  final bool wrongFlash;
  final bool hinted;
  final VoidCallback onTap;

  const _PartButton({
    super.key,
    required this.label,
    required this.done,
    required this.wrongFlash,
    required this.hinted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: done ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(
              minHeight: TownTheme.minTouch, minWidth: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: done
                ? TownTheme.green.withValues(alpha: 0.4)
                : (wrongFlash
                    ? TownTheme.coral.withValues(alpha: 0.5)
                    : TownTheme.blue.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hinted ? TownTheme.yellow : TownTheme.blue,
              width: hinted ? 6 : 3,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (done)
                  const Icon(Icons.check_circle, color: TownTheme.green),
                if (done) const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestBanner extends StatelessWidget {
  final String text;
  const _RequestBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TownTheme.yellow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
