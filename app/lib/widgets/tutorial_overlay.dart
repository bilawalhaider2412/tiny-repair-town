/// Skippable tutorial overlay: steps through the level's tutorial script.
///
/// Shown on first entry to tutorial levels (spec §4: skippable demonstration).
/// Back closes this overlay before anything else (spec §10).
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';

import '../app_theme.dart';
import '../app_state.dart';
import 'big_button.dart';

class TutorialOverlay extends StatefulWidget {
  final AppState appState;
  final List<String> script;
  final VoidCallback onDone;

  const TutorialOverlay({
    super.key,
    required this.appState,
    required this.script,
    required this.onDone,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _step = 0;

  void _finish() => widget.onDone();

  @override
  Widget build(BuildContext context) {
    final lang = widget.appState.lang;
    return Container(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.script[_step],
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_step + 1} / ${widget.script.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      BigButton(
                        label: tr('close', lang),
                        onPressed: _finish,
                        color: TownTheme.yellow,
                        buttonKey: const Key('tutorial_skip'),
                      ),
                      if (_step < widget.script.length - 1)
                        BigButton(
                          label: '→',
                          onPressed: () =>
                              setState(() => _step += 1),
                          buttonKey: const Key('tutorial_next'),
                        )
                      else
                        BigButton(
                          label: tr('letsPlay', lang),
                          onPressed: _finish,
                          buttonKey: const Key('tutorial_start'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
