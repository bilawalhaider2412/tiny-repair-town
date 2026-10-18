/// Parent area (spec §17).
///
/// - The gate is a written instruction plus a *randomized* hold-to-unlock
///   interaction (2–4 s, re-rolled every attempt): an adult action, not a
///   checkbox and not a gameplay puzzle. The gate copy states plainly that
///   it discourages accidental access and is not identity verification.
/// - Gate access expires on app backgrounding, on relaunch (state is
///   in-memory only), and after a short inactivity period (2 minutes).
///   Back, deep links and direct route navigation cannot bypass it: the
///   gated content only renders while [_unlocked] is true on this route.
/// - Behind the gate: language/audio/accessibility settings, a local
///   progress summary, neutral full-game information (no purchase button —
///   billing is interface-only until the owner sets it up, spec §18), a
///   privacy note, and progress reset with confirmation. Reset never erases
///   purchase ownership (SaveStore.resetProgress keeps the entitlement).
/// - No external links, no support-message sending: nothing leaves the device.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../widgets/big_button.dart';

class ParentsScreen extends StatefulWidget {
  final AppState appState;

  const ParentsScreen({super.key, required this.appState});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen>
    with WidgetsBindingObserver {
  /// In-memory only: relaunching the app (or reopening this route) always
  /// starts locked.
  bool _unlocked = false;

  /// Randomized hold challenge, re-rolled on every lock (spec §17: a
  /// randomized interaction that is not a standard child gameplay puzzle).
  int _holdSeconds = 3;
  double _holdProgress = 0;
  Timer? _holdTimer;

  /// Short inactivity period after which the gate expires (spec §17).
  Timer? _inactivityTimer;
  static const _inactivityLimit = Duration(minutes: 2);

  bool _resetDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _newChallenge();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The gate expires when the app backgrounds.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _relock();
    }
  }

  void _newChallenge() {
    _holdSeconds = 2 + Random().nextInt(3); // 2, 3 or 4 seconds
    _holdProgress = 0;
  }

  void _relock() {
    _holdTimer?.cancel();
    _inactivityTimer?.cancel();
    _newChallenge();
    if (_unlocked && mounted) {
      setState(() {
        _unlocked = false;
        _resetDone = false;
      });
    }
  }

  void _noteParentActivity() {
    if (!_unlocked) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityLimit, () {
      if (mounted) _relock();
    });
  }

  void _startHold() {
    if (_unlocked) return;
    _holdTimer?.cancel();
    final totalTicks = _holdSeconds * 10;
    var ticks = 0;
    _holdTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      ticks++;
      if (ticks >= totalTicks) {
        timer.cancel();
        setState(() {
          _unlocked = true;
          _holdProgress = 0;
        });
        _noteParentActivity();
      } else {
        setState(() => _holdProgress = ticks / totalTicks);
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    if (mounted && !_unlocked && _holdProgress != 0) {
      setState(() => _holdProgress = 0);
    }
  }

  Future<void> _confirmReset(String lang) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('resetConfirmTitle', lang)),
        content: Text(tr('resetConfirmBody', lang)),
        actions: [
          TextButton(
            key: const Key('reset_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel', lang)),
          ),
          TextButton(
            key: const Key('reset_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              tr('resetProgress', lang),
              style: const TextStyle(color: TownTheme.coral),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await widget.appState.resetProgress();
      if (mounted) setState(() => _resetDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final lang = appState.lang;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: tr('close', lang),
        ),
        title: Text(tr('parentGateTitle', lang)),
      ),
      body: SafeArea(
        child: _unlocked ? _buildSettings(context) : _buildGate(context),
      ),
    );
  }

  // --- Gate ---------------------------------------------------------------

  Widget _buildGate(BuildContext context) {
    final lang = widget.appState.lang;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.family_restroom,
                    size: 64, color: TownTheme.blue),
                const SizedBox(height: 16),
                Text(
                  tr('parentGateTitle', lang),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  tr('parentGateNote', lang),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  tr('parentGateHold', lang)
                      .replaceAll('{n}', _holdSeconds.toString()),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  key: const Key('parent_hold_button'),
                  onTapDown: (_) => _startHold(),
                  onTapUp: (_) => _cancelHold(),
                  onTapCancel: _cancelHold,
                  child: Container(
                    constraints: const BoxConstraints(
                        minHeight: TownTheme.minTouch),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: TownTheme.green.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: TownTheme.green, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fingerprint,
                            size: 40, color: TownTheme.ink),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            key: const Key('parent_hold_progress'),
                            value: _holdProgress,
                            minHeight: 12,
                            backgroundColor:
                                TownTheme.ink.withValues(alpha: 0.15),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    TownTheme.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Settings (behind the gate) ------------------------------------------

  Widget _buildSettings(BuildContext context) {
    final appState = widget.appState;
    final lang = appState.lang;
    final audio = appState.saveStore.data.audio;
    final a11y = appState.saveStore.data.accessibility;
    final completed = appState.completedLevels.length;
    final stickers = appState.stickers.length;
    return Listener(
      // The gate expires after a short inactivity period.
      onPointerDown: (_) => _noteParentActivity(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: tr('progressSummary', lang),
            children: [
              _SummaryRow(
                  label: tr('activitiesComplete', lang),
                  value: '$completed / 20'),
              _SummaryRow(
                  label: tr('stickersEarned', lang),
                  value: '$stickers'),
            ],
          ),
          _SectionCard(
            title: tr('sound', lang),
            children: [
              _ToggleRow(
                label: tr('music', lang),
                value: audio['music'] != false,
                onChanged: (v) => appState.setAudio('music', v),
              ),
              _ToggleRow(
                label: tr('effects', lang),
                value: audio['effects'] != false,
                onChanged: (v) => appState.setAudio('effects', v),
              ),
              _ToggleRow(
                label: tr('narration', lang),
                value: audio['narration'] != false,
                onChanged: (v) => appState.setAudio('narration', v),
              ),
            ],
          ),
          _SectionCard(
            title: tr('accessibility', lang),
            children: [
              _ToggleRow(
                label: tr('reducedMotion', lang),
                value: a11y['reducedMotion'] == true,
                onChanged: (v) =>
                    appState.setAccessibility('reducedMotion', v),
              ),
              _ToggleRow(
                label: tr('extraGuidance', lang),
                value: a11y['extraGuidance'] == true,
                onChanged: (v) =>
                    appState.setAccessibility('extraGuidance', v),
              ),
              _ToggleRow(
                label: tr('largeText', lang),
                value: a11y['largeText'] == true,
                onChanged: (v) =>
                    appState.setAccessibility('largeText', v),
              ),
            ],
          ),
          _SectionCard(
            title: tr('language', lang),
            children: [
              Center(
                child: TextButton(
                  key: const Key('parent_language_toggle'),
                  onPressed: () => appState.setLanguage(
                      lang == 'en' ? 'ur' : 'en'),
                  child: Text(
                    lang == 'en' ? 'اردو' : 'English',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          _SectionCard(
            title: tr('fullGameTitle', lang),
            children: [
              // Neutral information only: no price button, no pressure, no
              // purchase flow (billing is interface-only until the owner
              // sets it up — spec §18).
              Text(
                tr('fullGameBody', lang),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          _SectionCard(
            title: tr('privacyTitle', lang),
            children: [
              Text(
                tr('privacyNote', lang),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          BigButton(
            label: tr('resetProgress', lang),
            color: TownTheme.coral,
            onPressed: () => _confirmReset(lang),
            buttonKey: const Key('parent_reset'),
          ),
          if (_resetDone)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  tr('resetDone', lang),
                  key: const Key('reset_done_note'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: TownTheme.green),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyLarge),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // SwitchListTile keeps the full row tappable with a generous target.
    return SwitchListTile(
      title: Text(label,
          style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}
