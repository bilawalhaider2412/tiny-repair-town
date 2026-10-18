/// Widget tests: chain progression journeys, pause/resume checkpointing,
/// inactivity hint pulse, parent gate, Urdu RTL, and the save boundary.
///
/// The real app uses PathProviderSaveStorage; tests inject MemorySaveStorage.
///
/// NOTE (2026-10-18, environment quirk): on this VM, a second
/// `rootBundle.loadString` sequence inside a later testWidgets test never
/// completes (the first test's loads work). The level catalog is immutable
/// content, so it is loaded once in setUpAll and shared; every test still
/// gets a fresh AppState + MemorySaveStorage, keeping progress isolated.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_repair_town/models/level.dart';
import 'package:tiny_repair_town_app/app_state.dart';
import 'package:tiny_repair_town_app/level_repository.dart';
import 'package:tiny_repair_town_app/main.dart';
import 'package:tiny_repair_town_app/storage.dart';

late LevelRepository sharedRepository;
late Map<String, Level> sharedLevels;

Future<({TinyRepairTownApp app, AppState state})> pumpApp(
    WidgetTester tester) async {
  // Tall test surface: all five town-map cards fit without scrolling, so
  // level chips are always hittable (real devices scroll; the 800x600
  // default viewport would leave lower cards unbuilt).
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = await AppState.load(
    storage: MemorySaveStorage(),
    levels: sharedLevels,
  );
  final app =
      TinyRepairTownApp(state: state, repository: sharedRepository);
  await tester.pumpWidget(app);
  await tester.pump();
  return (app: app, state: state);
}

/// Home -> town map (dismissing the first-run language picker).
Future<void> goToTown(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pick_english')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('home_play')));
  await tester.pumpAndSettle();
}

/// Opens [levelId] from the town map and lands on its puzzle screen
/// (tutorial skipped). The level's chip must be playable.
Future<void> openLevel(WidgetTester tester, String levelId) async {
  await tester.tap(find.byKey(Key('level_$levelId')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('start_level')));
  await tester.pumpAndSettle();
  // Tutorial overlay on first entry (only some levels have one).
  final skip = find.byKey(const Key('tutorial_skip'));
  if (skip.evaluate().isNotEmpty) {
    await tester.tap(skip);
    await tester.pumpAndSettle();
  }
}

/// Solves the currently open level by driving its real config
/// (tap-to-place / tap-in-order / tap-tile-then-cell).
Future<void> solveLevel(WidgetTester tester, String levelId) async {
  final raw = sharedRepository.rawFor(levelId);
  final config = (raw['config'] as Map).cast<String, dynamic>();
  final level = sharedLevels[levelId]!;
  switch (level.puzzleType) {
    case 'matchParts':
      for (final s in (config['slots'] as List)) {
        final slot = (s as Map).cast<String, dynamic>();
        await tester.tap(find.byKey(Key('piece_${slot['acceptsPartId']}')));
        await tester.pump();
        await tester.tap(find.byKey(Key('slot_${slot['id']}')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }
    case 'buildOrder':
      final steps = (config['steps'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      final done = <String>{};
      while (done.length < steps.length) {
        var progressed = false;
        for (final st in steps) {
          final id = st['id'].toString();
          if (done.contains(id)) continue;
          final prereqs =
              ((st['prerequisites'] as List?) ?? []).map((e) => e.toString());
          if (prereqs.every(done.contains)) {
            await tester.tap(find.byKey(Key('part_${st['partId']}')));
            await tester.pump();
            done.add(id);
            progressed = true;
          }
        }
        if (!progressed) throw StateError('build order stuck in $levelId');
      }
    case 'restorePattern':
      for (final c in (config['cells'] as List)) {
        final cell = (c as Map).cast<String, dynamic>();
        await tester.tap(find.byKey(Key('tile_${cell['solutionTileId']}')));
        await tester.pump();
        await tester.tap(find.byKey(Key('cell_${cell['id']}')));
        await tester.pump();
      }
    default:
      throw StateError('cannot auto-solve ${level.puzzleType}');
  }
  // Let the async completion -> celebration navigation land.
  await tester.pump(const Duration(seconds: 1));
  expect(find.byKey(const Key('celebration_title')), findsOneWidget,
      reason: '$levelId should reach the celebration screen');
  await tester.tap(find.byKey(const Key('celebration_town')));
  await tester.pumpAndSettle();
}

/// Plays the chain L01..[through] in order (each level unlocked by the
/// previous one), solving every level through the real UI.
Future<void> playChain(WidgetTester tester, AppState state,
    {String through = 'L01'}) async {
  final n = int.parse(through.substring(1));
  for (var i = 1; i <= n; i++) {
    final id = 'L${i.toString().padLeft(2, '0')}';
    await openLevel(tester, id);
    await solveLevel(tester, id);
    expect(state.saveStore.data.completedLevels, contains(id));
  }
}

void main() {
  setUpAll(() async {
    sharedRepository = LevelRepository();
    sharedLevels = await sharedRepository.loadCatalog();
  });

  testWidgets(
      'L01: start -> place all 3 parts -> celebration -> sticker -> map improvement',
      (tester) async {
    final result = await pumpApp(tester);
    final state = result.state;
    final app = result.app;
    expect(app, isNotNull);
    await goToTown(tester);
    await playChain(tester, state, through: 'L01');

    // Celebration awarded the sticker idempotently in the save.
    expect(state.saveStore.data.completedLevels, contains('L01'));
    expect(state.saveStore.data.stickers, contains('sticker_little_wheel'));

    // Replay-safety: completing again never duplicates the sticker.
    await state.completeLevel(state.levels['L01']!);
    expect(
        state.saveStore.data.stickers
            .where((s) => s == 'sticker_little_wheel')
            .length,
        1);

    // Back on the town map: the workshop improvement entry is visible.
    expect(find.byKey(const Key('improvements_workshop')), findsOneWidget);
  });

  testWidgets('Chain: L02 unlocks after L01; L03 stays locked until L02',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    await goToTown(tester);

    // Fresh save: only L01 is playable.
    expect(find.byKey(const Key('level_L01')), findsOneWidget);
    expect(find.byKey(const Key('level_L02')), findsNothing);
    expect(find.byKey(const Key('level_L03')), findsNothing);

    await playChain(tester, state, through: 'L01');

    // L02 (matchParts) is now playable; L03 still needs L02.
    expect(find.byKey(const Key('level_L02')), findsOneWidget);
    expect(find.byKey(const Key('level_L03')), findsNothing);

    await playChain(tester, state, through: 'L02');
    expect(find.byKey(const Key('level_L03')), findsOneWidget);
  });

  testWidgets('Chain L01->L04: all three puzzle systems, gentle wrong tap',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    await goToTown(tester);
    await playChain(tester, state, through: 'L03');

    // L04 (buildOrder): a wrong-order tap first — gentle cue, no reset.
    await openLevel(tester, 'L04');
    final raw = sharedRepository.rawFor('L04');
    final steps = ((raw['config'] as Map)['steps'] as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final lastPart = steps.last['partId'].toString();
    await tester.tap(find.byKey(Key('part_$lastPart')));
    await tester.pump();
    expect(state.saveStore.data.completedLevels, isNot(contains('L04')));
    await solveLevel(tester, 'L04');
    expect(state.saveStore.data.completedLevels, contains('L04'));

    // Stickers accumulated deterministically along the chain, no duplicates.
    final stickers = state.saveStore.data.stickers;
    expect(stickers.toSet().length, stickers.length);
    expect(stickers.length, 4);
  });

  testWidgets('Pack levels stay neutrally locked: no price button, no pressure',
      (tester) async {
    await pumpApp(tester);
    await goToTown(tester);
    // L11 is authored pack content: no playable chip, neutral message only.
    expect(find.byKey(const Key('level_L11')), findsNothing);
    expect(find.text('More activities in Parents'), findsWidgets);
    // Stubs (if any remain) behave the same way.
    for (final level in sharedLevels.values.where((l) => l.stub)) {
      expect(find.byKey(Key('level_${level.id}')), findsNothing,
          reason: 'stub ${level.id} must not be playable');
    }
  });

  testWidgets('Pause/resume: system Back pauses, checkpoint restores progress',
      (tester) async {
    final result = await pumpApp(tester);
    final state = result.state;
    final app = result.app;
    expect(app, isNotNull);
    await goToTown(tester);
    await openLevel(tester, 'L01');

    // Place one piece.
    await tester.tap(find.byKey(const Key('piece_part_wheel')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('slot_slot_wheel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // System Back -> pause dialog (checkpoint saved), not an instant exit.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pause_resume')), findsOneWidget);

    // Resume: the placed piece is still in its slot.
    await tester.tap(find.byKey(const Key('pause_resume')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('piece_part_wheel')), findsNothing);

    // Leave for town, come back: checkpoint restored the piece.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pause_town')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('level_L01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_level')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('piece_part_wheel')), findsNothing,
        reason: 'checkpoint restored the placed wheel');
    expect(state.saveStore.data.completedLevels, isNot(contains('L01')));
  });

  testWidgets('Direct /level navigation cannot bypass locks', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('pick_english')));
    await tester.pumpAndSettle();
    // Bypass the town map entirely: push the level route directly.
    final context = tester.element(find.byKey(const Key('home_play')));
    Navigator.of(context).pushNamed('/level', arguments: 'L11');
    await tester.pumpAndSettle();
    // Neutral locked message — no puzzle, no hint button, no purchase UI.
    expect(find.text('More activities in Parents'), findsOneWidget);
    expect(find.byKey(const Key('hint_button')), findsNothing);
  });

  testWidgets('Rotation preserves puzzle state', (tester) async {
    await pumpApp(tester);
    await goToTown(tester);
    await openLevel(tester, 'L01');

    await tester.tap(find.byKey(const Key('piece_part_wheel')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('slot_slot_wheel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('piece_part_wheel')), findsNothing);

    // Rotate the device mid-level: engine state survives, layout recomputes.
    tester.view.physicalSize = const Size(2000, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('piece_part_wheel')), findsNothing,
        reason: 'placed wheel survives rotation');
    expect(find.byKey(const Key('slot_slot_wheel')), findsOneWidget);
    tester.view.physicalSize = const Size(800, 2000);
    await tester.pumpAndSettle();
  });

  testWidgets('Urdu: RTL directionality; toggle preserves progress',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    await goToTown(tester);
    await playChain(tester, state, through: 'L01');

    // Switch to Urdu from the town map.
    await tester.tap(find.byKey(const Key('language_toggle')));
    await tester.pumpAndSettle();
    expect(state.lang, 'ur');
    final rtlElement = tester.element(find.byKey(const Key('language_toggle')));
    expect(Directionality.of(rtlElement), TextDirection.rtl);

    // Progress survived the language switch.
    expect(state.saveStore.data.completedLevels, contains('L01'));

    // Switch back: LTR again, progress still intact.
    await tester.tap(find.byKey(const Key('language_toggle')));
    await tester.pumpAndSettle();
    final ltrElement = tester.element(find.byKey(const Key('language_toggle')));
    expect(Directionality.of(ltrElement), TextDirection.ltr);
    expect(state.saveStore.data.completedLevels, contains('L01'));
  });

  testWidgets('Inactivity pulse: hint button pulses once after ~10s idle',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    // Reduced motion: the pulse shows a static highlight ring (no motion),
    // which is observable in the test.
    state.saveStore.data.accessibility['reducedMotion'] = true;
    await goToTown(tester);
    await openLevel(tester, 'L01');

    // No interaction for 11s: the one-shot pulse fires.
    await tester.pump(const Duration(seconds: 11));
    expect(find.byKey(const Key('hint_pulse_ring')), findsOneWidget);

    // It never repeats: after the ring clears, no second pulse arrives.
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const Key('hint_pulse_ring')), findsNothing);
    await tester.pump(const Duration(seconds: 20));
    expect(find.byKey(const Key('hint_pulse_ring')), findsNothing);
  });

  testWidgets('Inactivity pulse: interaction resets the window',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    state.saveStore.data.accessibility['reducedMotion'] = true;
    await goToTown(tester);
    await openLevel(tester, 'L01');

    // Interact at 9s (inside the window), then wait 9 more: no pulse yet.
    await tester.pump(const Duration(seconds: 9));
    await tester.tap(find.byKey(const Key('hint_button')));
    await tester.pump(const Duration(seconds: 9));
    expect(find.byKey(const Key('hint_pulse_ring')), findsNothing);

    // A further idle stretch finally fires it once.
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('hint_pulse_ring')), findsOneWidget);
  });

  testWidgets(
      'Parent gate: hold unlocks; background relocks; reset keeps entitlement',
      (tester) async {
    final state = (await pumpApp(tester)).state;
    await tester.tap(find.byKey(const Key('pick_english')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home_parents')));
    await tester.pumpAndSettle();

    // Gate is showing; settings are not reachable without the hold.
    expect(find.byKey(const Key('parent_hold_button')), findsOneWidget);
    expect(find.byKey(const Key('parent_reset')), findsNothing);

    // Press and hold (challenge is 2-4s; 5s always clears it).
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('parent_hold_button'))));
    await tester.pump(const Duration(seconds: 5));
    await gesture.up();
    await tester.pumpAndSettle();

    // Behind the gate: settings + reset.
    expect(find.byKey(const Key('parent_hold_button')), findsNothing);
    expect(find.byKey(const Key('parent_reset')), findsOneWidget);

    // Reset keeps a granted entitlement (purchase ownership is not erased).
    state.saveStore.data.entitlement['granted'] = true;
    await tester.tap(find.byKey(const Key('parent_reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset_confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reset_done_note')), findsOneWidget);
    expect(state.saveStore.data.completedLevels, isEmpty);
    expect(state.saveStore.data.entitlement['granted'], isTrue);

    // Backgrounding expires the gate: the hold challenge is back on return.
    // (Frames are disabled while paused, so resume before pumping — this
    // mirrors what the user sees: background -> foreground -> gate locked.)
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('parent_hold_button')), findsOneWidget);
    expect(find.byKey(const Key('parent_reset')), findsNothing);
  });
}
