/// Level entry: character request card, then the puzzle for its system.
///
/// Routes matchParts -> MatchPartsScreen, buildOrder -> BuildOrderScreen,
/// restorePattern -> RestorePatternScreen. Stubs never reach here (the town
/// map only opens playable levels).
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';
import 'package:tiny_repair_town/models/level.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../game_text.dart';
import '../level_repository.dart';
import '../widgets/big_button.dart';
import 'puzzles/build_order_screen.dart';
import 'puzzles/match_parts_screen.dart';
import 'puzzles/restore_pattern_screen.dart';

class LevelScreen extends StatefulWidget {
  final AppState appState;
  final LevelRepository repository;
  final String levelId;

  const LevelScreen({
    super.key,
    required this.appState,
    required this.repository,
    required this.levelId,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final level = widget.appState.levels[widget.levelId];
    if (level == null) {
      return const Scaffold(
          body: Center(child: Text('Missing level')));
    }
    // Route-level guard: even a direct '/level' navigation can never open a
    // locked (chain- or entitlement-gated) level — it shows the same neutral
    // message as the town map (spec §4).
    if (!widget.appState.isPlayableNow(level)) {
      return _buildLocked(context, level);
    }
    if (!_started) return _buildRequest(context, level);
    final raw = widget.repository.rawFor(level.id);
    switch (level.puzzleType) {
      case 'matchParts':
        return MatchPartsScreen(
            appState: widget.appState, level: level, raw: raw);
      case 'buildOrder':
        return BuildOrderScreen(
            appState: widget.appState, level: level, raw: raw);
      case 'restorePattern':
        return RestorePatternScreen(
            appState: widget.appState, level: level, raw: raw);
      default:
        return const Scaffold(
            body: Center(child: Text('Unsupported puzzle type')));
    }
  }

  /// Neutral locked state for direct route navigation at a level the child
  /// cannot play yet (spec §4): no puzzle, no price, just the Parents note.
  Widget _buildLocked(BuildContext context, Level level) {
    final lang = widget.appState.lang;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: tr('backToTown', lang),
        ),
        title: Text(level.title[lang] ?? level.title['en'] ?? ''),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 64, color: TownTheme.blue),
                const SizedBox(height: 16),
                Text(
                  tr('moreInParents', lang),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequest(BuildContext context, Level level) {
    final lang = widget.appState.lang;
    final character = localizedName(characterNames, level.requester, lang);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: tr('backToTown', lang),
        ),
        title: Text(level.title[lang] ?? level.title['en'] ?? ''),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: TownTheme.coral,
                      child: Icon(Icons.person,
                          size: 48, color: TownTheme.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      character,
                      style:
                          Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      level.request[lang] ?? level.request['en'] ?? '',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    BigButton(
                      label: tr('letsPlay', lang),
                      onPressed: () => setState(() => _started = true),
                      buttonKey: const Key('start_level'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
