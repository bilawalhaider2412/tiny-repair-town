/// Repair celebration (spec §4, steps 6–9).
///
/// Short, skippable repaired-object animation; the sticker was already awarded
/// idempotently via SaveStore.completeLevel before this screen opened. Shows
/// the visible town-map improvement entry, then offers replay or town return.
/// Reduced-motion: static, no animation.
library;

import 'package:flutter/material.dart';
import 'package:tiny_repair_town/core/localization.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../level_repository.dart';
import '../widgets/big_button.dart';

class CelebrationScreen extends StatefulWidget {
  final AppState appState;
  final LevelRepository repository;
  final String levelId;

  const CelebrationScreen({
    super.key,
    required this.appState,
    required this.repository,
    required this.levelId,
  });

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (!widget.appState.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final lang = appState.lang;
    final level = appState.levels[widget.levelId];
    final raw = widget.repository.rawFor(widget.levelId);
    final rewardName = ((raw['reward'] as Map?)?[lang] ??
            (raw['reward'] as Map?)?['en'] ??
            level?.rewardId ??
            '')
        .toString();
    final improvement = ((raw['mapImprovement'] as Map?)?[lang] ??
            (raw['mapImprovement'] as Map?)?['en'] ??
            '')
        .toString();

    return PopScope(
      canPop: false, // Back from celebration goes to town, never into the puzzle.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToTown();
      },
      child: Scaffold(
        body: SafeArea(
          child: GestureDetector(
            key: const Key('celebration_skip'),
            onTap: () => setState(() => _skipped = true),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RepairedObject(
                        controller: _controller, skipped: _skipped),
                    const SizedBox(height: 16),
                    Text(
                      tr('wellDone', lang),
                      style:
                          Theme.of(context).textTheme.headlineSmall,
                      key: const Key('celebration_title'),
                    ),
                    const SizedBox(height: 8),
                    // Sticker award (idempotent — replay never duplicates).
                    _StickerBadge(
                        rewardId: level?.rewardId ?? '',
                        name: rewardName),
                    const SizedBox(height: 12),
                    // Visible town-map improvement entry.
                    if (improvement.isNotEmpty)
                      Card(
                        key: const Key('map_improvement'),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 24),
                        color: TownTheme.green
                            .withValues(alpha: 0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.map,
                                  color: TownTheme.ink),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  improvement,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: [
                        BigButton(
                          label: tr('replay', lang),
                          color: TownTheme.yellow,
                          onPressed: () =>
                              Navigator.of(context).pushReplacementNamed(
                            '/level',
                            arguments: widget.levelId,
                          ),
                          buttonKey: const Key('celebration_replay'),
                        ),
                        BigButton(
                          label: tr('backToTown', lang),
                          onPressed: _goToTown,
                          buttonKey:
                              const Key('celebration_town'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToTown() => Navigator.of(context)
      .pushNamedAndRemoveUntil('/town', (r) => r.isFirst);
}

class _RepairedObject extends StatelessWidget {
  final AnimationController controller;
  final bool skipped;

  const _RepairedObject({required this.controller, required this.skipped});

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: TownTheme.green,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.build,
          size: 72, color: TownTheme.white),
    );
    if (skipped) return icon; // skippable: tap anywhere to stop the motion
    return ScaleTransition(
      scale: Tween(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      ),
      child: icon,
    );
  }
}

class _StickerBadge extends StatelessWidget {
  final String rewardId;
  final String name;

  const _StickerBadge({required this.rewardId, required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('sticker_award'),
      color: TownTheme.yellow.withValues(alpha: 0.6),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star,
                size: 40, color: TownTheme.coral),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
