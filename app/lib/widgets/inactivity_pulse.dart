/// Inactivity hint pulse (spec §9).
///
/// After ~10 seconds of inactivity the *hint button* gently pulses **once** —
/// it never auto-solves, never repeats, and never fires while the app is
/// backgrounded, audio is playing, a menu is open, or an animation blocks
/// input.
///
/// [InactivityPulse] is the timer/state helper owned by a puzzle screen;
/// [PulsingHintButton] is the AppBar hint button that plays the one-shot
/// visual when the helper fires.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Tracks inactivity and fires a single pulse signal.
///
/// The screen drives the lifecycle:
/// - [start] when the puzzle becomes interactive (after the tutorial),
/// - [pause] when a menu overlay opens or the app backgrounds,
/// - [reset] on any pointer interaction (restarts the 10s window),
/// - [dispose] with the screen.
///
/// If [isSuppressed] is true at the deadline (menu open, animation running,
/// audio playing, …) the pulse is *deferred*, not dropped: the timer
/// restarts and the pulse still fires exactly once, the first time
/// conditions allow.
class InactivityPulse {
  /// True while the pulse must not fire (evaluated at each deadline).
  final bool Function() isSuppressed;

  /// Inactivity window before the pulse (spec: ~10 seconds).
  final Duration inactivity;

  /// Incremented exactly once, when the pulse fires.
  final ValueNotifier<int> signal = ValueNotifier<int>(0);

  Timer? _timer;
  bool _fired = false;
  bool _disposed = false;

  InactivityPulse({
    required this.isSuppressed,
    this.inactivity = const Duration(seconds: 10),
  });

  /// True after the pulse has fired (it never fires twice).
  bool get fired => _fired;

  /// (Re)starts the inactivity window. No-op once fired.
  void start() {
    if (_fired || _disposed) return;
    _timer?.cancel();
    _timer = Timer(inactivity, _onTimeout);
  }

  /// Pauses tracking (menu opened, app backgrounded). Resume with [start].
  void pause() {
    _timer?.cancel();
  }

  /// Restarts the window after user interaction. No-op once fired.
  void reset() {
    if (_fired || _disposed) return;
    start();
  }

  void _onTimeout() {
    if (_fired || _disposed) return;
    if (isSuppressed()) {
      // Deferred, not dropped: try again after a fresh window.
      start();
      return;
    }
    _fired = true;
    _timer?.cancel();
    signal.value++;
  }

  /// Cancels the timer and releases the signal notifier.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    signal.dispose();
  }
}

/// The hint button with a one-shot gentle pulse.
///
/// When [pulseSignal] increments, the button pulses once: a soft scale
/// pulse normally, or — under reduced motion — a static highlight ring with
/// no motion at all (spec §14: no non-skippable animation).
class PulsingHintButton extends StatefulWidget {
  final ValueListenable<int> pulseSignal;
  final VoidCallback onPressed;
  final String tooltip;
  final bool reducedMotion;
  final Key? buttonKey;

  const PulsingHintButton({
    super.key,
    required this.pulseSignal,
    required this.onPressed,
    required this.tooltip,
    required this.reducedMotion,
    this.buttonKey,
  });

  @override
  State<PulsingHintButton> createState() => _PulsingHintButtonState();
}

class _PulsingHintButtonState extends State<PulsingHintButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _highlighted = false;
  int _lastSignal = 0;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1),
    ]).animate(_controller);
    _lastSignal = widget.pulseSignal.value;
    widget.pulseSignal.addListener(_onSignal);
  }

  @override
  void dispose() {
    widget.pulseSignal.removeListener(_onSignal);
    _highlightTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSignal() {
    if (!mounted) return;
    if (widget.pulseSignal.value == _lastSignal) return;
    _lastSignal = widget.pulseSignal.value;
    if (widget.reducedMotion) {
      // No motion: a static highlight ring that fades from attention
      // on its own after a couple of seconds.
      setState(() => _highlighted = true);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlighted = false);
      });
    } else {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (_highlighted)
          Container(
            key: const Key('hint_pulse_ring'),
            width: TownTheme.minTouch,
            height: TownTheme.minTouch,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TownTheme.yellow.withValues(alpha: 0.7),
            ),
          ),
        ScaleTransition(
          scale: _scale,
          child: IconButton(
            key: widget.buttonKey,
            icon: const Icon(Icons.lightbulb_outline, size: 32),
            onPressed: widget.onPressed,
            tooltip: widget.tooltip,
          ),
        ),
      ],
    );
  }
}
