/// Town map (spec §3, §4).
///
/// Five locations. Stage 3 exposes L01/L03/L04 as directly playable (the three
/// system showcases); every other level shows a neutral locked state with
/// "More activities in Parents" — no price button, no pressure (spec §4).
/// Completed levels show their improvement entry on the map.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';
import 'package:tiny_repair_town/models/level.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../game_text.dart';
import '../level_repository.dart';
import '../widgets/big_button.dart';

class TownMapScreen extends StatelessWidget {
  final AppState appState;
  final LevelRepository repository;

  const TownMapScreen({
    super.key,
    required this.appState,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.lang;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('appTitle', lang)),
        actions: [
          _LanguageToggle(appState: appState),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: locationOrder.length,
          itemBuilder: (context, i) {
            final locationId = locationOrder[i];
            return _LocationCard(
              appState: appState,
              repository: repository,
              locationId: locationId,
            );
          },
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final AppState appState;
  final LevelRepository repository;
  final String locationId;

  const _LocationCard({
    required this.appState,
    required this.repository,
    required this.locationId,
  });

  @override
  Widget build(BuildContext context) {
    final lang = appState.lang;
    final levels = appState.levels.values
        .where((l) => l.locationId == locationId)
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final completed = appState.completedLevels;
    final improvements = levels
        .where((l) => completed.contains(l.id))
        .map((l) => ((repository.rawFor(l.id)['mapImprovement'] as Map?)?[lang] ??
                (repository.rawFor(l.id)['mapImprovement'] as Map?)?['en'] ??
                '')
            .toString())
        .where((s) => s.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on,
                    color: TownTheme.coral, size: 32),
                const SizedBox(width: 8),
                Text(
                  localizedName(locationNames, locationId, lang),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final level in levels)
                  _levelChip(context, level)
              ],
            ),
            if (improvements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                key: Key('improvements_$locationId'),
                children: [
                  for (final text in improvements)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.eco,
                              color: TownTheme.green, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                tr('moreInParents', lang),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: TownTheme.ink.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _levelChip(BuildContext context, Level level) {
    final lang = appState.lang;
    final playable = appState.isPlayableNow(level);
    final done = appState.completedLevels.contains(level.id);
    if (playable) {
      return BigButton(
        label:
            '${done ? '★ ' : ''}${level.title[lang] ?? level.title['en'] ?? level.id}',
        color: done ? TownTheme.green : TownTheme.blue,
        onPressed: () =>
            Navigator.of(context).pushNamed('/level', arguments: level.id),
        buttonKey: Key('level_${level.id}'),
      );
    }
    // Neutral locked state: no price button, no pressure.
    return Semantics(
      label: '${level.title[lang] ?? level.id} — ${tr('moreInParents', lang)}',
      child: Container(
        constraints:
            const BoxConstraints(minHeight: TownTheme.minTouch),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: TownTheme.cream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TownTheme.ink.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                level.title[lang] ?? level.title['en'] ?? level.id,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final AppState appState;
  const _LanguageToggle({required this.appState});

  @override
  Widget build(BuildContext context) {
    final lang = appState.lang;
    return TextButton(
      key: const Key('language_toggle'),
      onPressed: () =>
          appState.setLanguage(lang == 'en' ? 'ur' : 'en'),
      child: Text(
        lang == 'en' ? 'اردو' : 'English',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
