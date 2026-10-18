/// App-wide game state: save store, level catalog, settings, availability.
///
/// Single state-management approach (ARCHITECTURE.md): one ChangeNotifier per
/// feature area. This is the app/session feature; puzzle screens own their own
/// engine state and drive the pure-Dart engines directly.
library;

import 'package:flutter/foundation.dart';
import 'package:tiny_repair_town/core/save_data.dart';
import 'package:tiny_repair_town/models/level.dart';

import 'audio.dart';

class AppState extends ChangeNotifier {
  final SaveStore saveStore;
  final Map<String, Level> levels;

  AppState._(this.saveStore, this.levels);

  static Future<AppState> load({
    required SaveStorage storage,
    required Map<String, Level> levels,
  }) async {
    final store = await SaveStore.load(storage);
    return AppState._(store, levels);
  }

  // --- Settings -----------------------------------------------------------

  String get lang => saveStore.data.language;

  bool get reducedMotion =>
      saveStore.data.accessibility['reducedMotion'] == true;

  bool get extraGuidance =>
      saveStore.data.accessibility['extraGuidance'] == true;

  bool get largeText =>
      saveStore.data.accessibility['largeText'] == true;

  Future<void> setLanguage(String value) async {
    if (value != 'en' && value != 'ur') return;
    saveStore.data.language = value;
    await saveStore.save();
    notifyListeners(); // progress is untouched: switch preserves it
  }

  /// Parent-gated setting toggle (sound). Applies to the audio service too.
  Future<void> setAudio(String key, bool value) async {
    saveStore.data.audio[key] = value;
    AudioService.instance.applySettings(
      music: saveStore.data.audio['music'] == true,
      effects: saveStore.data.audio['effects'] == true,
      narration: saveStore.data.audio['narration'] == true,
    );
    await saveStore.save();
    notifyListeners();
  }

  /// Parent-gated setting toggle (accessibility).
  Future<void> setAccessibility(String key, bool value) async {
    saveStore.data.accessibility[key] = value;
    await saveStore.save();
    notifyListeners();
  }

  // --- Progress ------------------------------------------------------------

  Set<String> get completedLevels =>
      saveStore.data.completedLevels.toSet();

  Set<String> get stickers => saveStore.data.stickers.toSet();

  /// Local entitlement cache (spec §18). NEVER treat this as purchase
  /// verification: a user-editable local flag is not proof of purchase.
  /// Production verification is server-side once the owner sets up billing;
  /// this only remembers a previously verified grant for offline access.
  bool get entitlementGranted =>
      saveStore.data.entitlement['granted'] == true;

  /// Whether the child may open this level right now.
  ///
  /// Launch-table rule (spec §4): L01 always; Ln (n>1) needs L(n−1) complete
  /// plus its authored prerequisites; L11–L20 additionally need the
  /// entitlement. Stub (un-authored) levels are never playable.
  bool isPlayableNow(Level level) =>
      level.isPlayable && isAvailableByChain(level);

  /// Chain/entitlement availability shared by the map and the level screens.
  bool isAvailableByChain(Level level) => Level.isLevelAvailable(
        level: level,
        completedLevels: completedLevels,
        entitlementGranted: entitlementGranted,
      );

  /// Idempotent completion: sticker + map improvement recorded once,
  /// checkpoint for the level cleared, then persisted.
  Future<void> completeLevel(Level level) async {
    saveStore.completeLevel(level.id, level.rewardId);
    saveStore.data.checkpoints.remove(level.id);
    await saveStore.save();
    notifyListeners();
  }

  /// Parent-initiated progress reset (behind the parent gate): clears
  /// completions, stickers and checkpoints but keeps the purchase
  /// entitlement and settings intact (spec §17).
  Future<void> resetProgress() async {
    saveStore.resetProgress();
    await saveStore.save();
    notifyListeners();
  }

  /// Stable-boundary checkpoint (level start, pause, completion).
  Future<void> saveCheckpoint(
      String levelId, Map<String, dynamic> snapshot) async {
    saveStore.data.checkpoints[levelId] = snapshot;
    await saveStore.save();
  }

  Map<String, dynamic>? checkpointFor(String levelId) {
    final raw = saveStore.data.checkpoints[levelId];
    return raw is Map ? raw.cast<String, dynamic>() : null;
  }

  // --- First-run language picker -------------------------------------------

  bool get languagePicked =>
      (saveStore.data.checkpoints['__flags'] as Map?)?['languagePicked'] ==
      true;

  Future<void> markLanguagePicked() async {
    final flags =
        (saveStore.data.checkpoints['__flags'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    flags['languagePicked'] = true;
    saveStore.data.checkpoints['__flags'] = flags;
    await saveStore.save();
  }

  // --- Tutorial tracking ----------------------------------------------------

  bool tutorialSeen(String levelId) {
    final seen = (saveStore.data.checkpoints['__flags'] as Map?)?['tutorialSeen'];
    return seen is List && seen.contains(levelId);
  }

  Future<void> markTutorialSeen(String levelId) async {
    final flags =
        (saveStore.data.checkpoints['__flags'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
    final seen = (flags['tutorialSeen'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
    if (!seen.contains(levelId)) seen.add(levelId);
    flags['tutorialSeen'] = seen;
    saveStore.data.checkpoints['__flags'] = flags;
    await saveStore.save();
  }

  // --- Background pause hook -----------------------------------------------

  /// Set by the active puzzle screen; invoked on app backgrounding so the
  /// screen can pause and checkpoint. Cleared when the screen disposes.
  VoidCallback? onBackgroundPause;
}
