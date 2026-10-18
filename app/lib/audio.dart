/// Audio hooks for Tiny Repair Town.
///
/// No real audio assets ship in Stage 3 (see docs/ASSET_LIST.md — every audio
/// row is "missing"). This service keeps the lifecycle and settings wiring in
/// place so real playback can land later without restructuring.
///
/// Rules honoured here (spec §10, §12):
/// - never autoplay on resume,
/// - pause/stop everything when the app backgrounds.
library;

/// Minimal audio facade. All methods are safe no-ops until real assets land.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool _musicOn = true;
  bool _effectsOn = true;
  bool _narrationOn = true;

  bool get isMusicOn => _musicOn;
  bool get isEffectsOn => _effectsOn;
  bool get isNarrationOn => _narrationOn;

  /// True while any audio is actually playing. Always false until real
  /// playback lands (Stage 5); the inactivity hint pulse checks this so it
  /// never fires over playing audio (spec §9).
  bool get isPlaying => false;

  /// Applies the player's audio settings (from the save file).
  void applySettings({bool? music, bool? effects, bool? narration}) {
    if (music != null) _musicOn = music;
    if (effects != null) _effectsOn = effects;
    if (narration != null) _narrationOn = narration;
  }

  /// Would play a short UI/puzzle effect. No-op: no audio assets yet.
  void playEffect(String id) {
    if (!_effectsOn) return;
    // TODO(Stage 5): play bundled effect asset `assets/audio/fx/$id.*`.
  }

  /// Would play (or replay) the level instruction narration. No-op.
  void playNarration(String narrationId, String lang) {
    if (!_narrationOn) return;
    // TODO(Stage 5): play bundled narration `assets/audio/narration/$lang/$narrationId.*`.
  }

  /// Pauses/stops all audio (backgrounding, interruptions).
  void pauseAll() {
    // No-op until real playback exists.
  }

  /// Called on resume. Deliberately does NOT restart music/effects/narration:
  /// returning from background must not unexpectedly autoplay loud audio.
  void onResumedWithoutAutoplay() {
    // Intentionally empty.
  }
}
