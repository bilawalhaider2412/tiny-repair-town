/// Pause overlay shared by the puzzle screens.
///
/// Back closes overlays first (handled by each screen), then pauses here with
/// Resume / Back-to-town. Checkpoint is saved by the screen before showing.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';

import '../app_state.dart';
import '../app_theme.dart';
import 'big_button.dart';

class PauseDialog extends StatelessWidget {
  final AppState appState;
  final VoidCallback onResume;

  const PauseDialog({
    super.key,
    required this.appState,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.lang;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('appTitle', lang),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                BigButton(
                  label: tr('resume', lang),
                  onPressed: onResume,
                  buttonKey: const Key('pause_resume'),
                ),
                const SizedBox(height: 12),
                BigButton(
                  label: tr('backToTown', lang),
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/town', (r) => r.isFirst),
                  color: TownTheme.yellow,
                  buttonKey: const Key('pause_town'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
