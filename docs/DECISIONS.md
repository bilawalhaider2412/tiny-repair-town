# Decisions — Tiny Repair Town

Short, dated record of reversible and structural decisions. Update when a
decision is revisited.

## 2026-10-18 — Pure-Dart puzzle engines, zero Flutter dependency

Engines (matchParts/buildOrder/restorePattern) are implemented in Dart only,
with no Flutter imports. Rationale: the only runnable toolchain on this VM is
the Dart VM, so game logic must be testable without Flutter; it also keeps
rules independently testable forever, with Flutter later acting as a thin
rendering/input shell. (Engines assigned to sibling agent; `lib/puzzles/`
currently an empty directory.)

## 2026-10-18 — Content schema v1: proportional coordinates

All positions and distances in level JSON are 0.0–1.0 proportions of the
work-area box, per spec §5 ("define positions proportionally so resizing does
not break matching"). Locked in `docs/CONTENT_SCHEMA.md`; any schema change
bumps `schemaVersion` and gets a migration note.

## 2026-10-18 — Three hint strengths, authored per level

`hints` holds exactly 3 entries with strengths 1,2,3 (gentle highlight →
show target/step → demonstrate one correct action). Always free, unlimited.
Validator enforces the count and both languages.

## 2026-10-18 — Finale (L20) is composed stages, not a fourth engine

L20's `config.stages` reuses the three existing systems; per-stage checkpoints
live in `SaveData.checkpoints["L20"].completedStages`. No new engine type is
introduced for the finale (spec §8).

## 2026-10-18 — Save schema v2 with atomic writes

Writes go temp-file → rename with a `.bak` copy of the last good save;
corrupt-primary + corrupt-backup boots fresh defaults flagged
`recoveredFromCorrupt: true` (surfaced, never crash). v1 → v2 migration adds
`accessibility.extraGuidance` (default false). Stickers are a set — migration
and replay must never duplicate them. Entitlement cache is separate from
gameplay progress (reset ≠ revoke).

## 2026-10-18 — Urdu RTL via Directionality + bundled fonts, no blind mirroring

Urdu uses proper RTL text layout and shaping with bundled offline fonts;
layout mirrors navigation but **not** pictures, directional game clues, or
authored solutions (spec §13). Urdu strings in level JSONs are draft copy;
fluent-speaker review is still required (see KNOWN_ISSUES.md).

## 2026-10-18 — L07 distractor-piece design

L07 (Toy Train Tune-up) ships four slots among five tray pieces; the fifth is
`isDistractor: true` and matches no slot. Distractors are explicitly flagged
in content and validated to be unsolvable, keeping them harmless rather than
confusing.

## 2026-10-18 — No Flutter yet; web preview ≠ Android proof

The Flutter toolchain and Android SDK do not exist on this VM, so Stage 2
delivers logic + content + a dev web preview of L01 only. Per spec §1 the
preview supports development but establishes nothing about Android
compatibility, performance, or billing. No claim to the contrary is made
anywhere in these docs.

## 2026-10-18 — Stage 3: Flutter app shell in repo (app/)

`flutter create --project-name tiny_repair_town_app --org com.example
--platforms=android,web app` under `~/workspace/tiny-repair-town/app/`.
`com.example` is temporary scaffolding: the real application ID is the owner
placeholder [FINAL_ANDROID_APPLICATION_ID] (spec §25), to be set before any
store work. No Android SDK installed (out of scope); no APK/AAB produced.

## 2026-10-18 — Single-source content via path dependency

The app depends on the pure-Dart package as `tiny_repair_town: path: ../`.
Parent `pubspec.yaml` declares `flutter: assets: - assets/levels/`; the app
loads `packages/tiny_repair_town/assets/levels/level_<ID>.json` through
rootBundle. Engines, validation and JSON are reused, never duplicated.

## 2026-10-18 — Stage 3 showcase deviation: L01/L03/L04 directly playable

Stage 3 exposes exactly three levels — L01 (system A), L03 (system C), L04
(system B) — as directly playable showcases, bypassing the launch-table chain
(L03 would otherwise need stub L02; L04 would need L03). All other levels show
the neutral locked state "More activities in Parents" with no price button or
pressure. `Level.isLevelAvailable` remains the chain/entitlement rule and is
kept as `AppState.isAvailableByChain` for Stage 4, when full progression
(L02, L05–L10, pack gating) is authored. This is a deliberate, documented
deviation, not a design change.

## 2026-10-18 — QA audit: chain progression replaces the Stage 3 showcase

The showcase deviation above is retired. With all 20 levels authored,
`AppState.isPlayableNow` is now `level.isPlayable && Level.isLevelAvailable`
— the spec §4 launch-table rule (L01–L10 free offline in chain order,
L11–L20 gated on the entitlement cache). The `/level` route re-checks
availability so direct navigation cannot bypass a lock; locked levels show
the neutral "More activities in Parents" state, never a price button.

## 2026-10-18 — QA audit: parent gate is a randomized hold, not a stub

The Stage 3 "parent area arrives in Stage 6" stub is replaced with a real
gate per spec §17: a written instruction plus a press-and-hold challenge of
randomized 2–4 s (re-rolled every attempt) — an adult action, not a
checkbox, not arithmetic, not a gameplay puzzle. Gate copy states it
discourages accidental access and is not identity verification. Access
expires on backgrounding, on relaunch (in-memory only) and after 2 minutes
of inactivity. Behind the gate: sound/accessibility/language settings, a
local progress summary, neutral full-game info (no purchase button —
billing is interface-only until owner setup), a privacy note, and
reset-with-confirmation that preserves the entitlement. No external links.

## 2026-10-18 — QA audit: Urdu needs localization delegates (bug fix)

The app set `locale: Locale('ur')` but never provided
`localizationsDelegates`, so switching to Urdu crashed with "No
MaterialLocalizations found" — the Urdu toggle was completely broken.
Fixed by adding `flutter_localizations` (SDK package) and the three global
delegates in `MaterialApp`; they also supply the RTL Directionality.

## 2026-10-18 — QA audit: hint button pulses once after ~10s idle (spec §9)

New `InactivityPulse` helper + `PulsingHintButton`: after ~10 s of no
interaction the hint button gently pulses exactly once. Suppressed while a
menu is open, an animation blocks input, audio is playing, or the app is
backgrounded (deferred, not dropped, until conditions clear). Reduced
motion swaps the scale pulse for a static highlight ring.

## 2026-10-18 — Per-feature ChangeNotifier stores, no third-party state package

`AppState` (session/save/settings) plus one engine-driving State per puzzle
screen, per the ARCHITECTURE.md state-management decision. Persistence:
`PathProviderSaveStorage` (real app, application documents dir, atomic writes
via FileSaveStorage) and `MemorySaveStorage` (widget tests). Checkpoints saved
at level start, pause and completion; completion via `SaveStore.completeLevel`
(idempotent stickers).

## 2026-10-18 — Pause/back contract

PopScope with canPop:false on every puzzle screen: Back closes the tutorial
overlay first, then pauses (Resume / Back-to-town) with a checkpoint save.
Backgrounding triggers the same pause via WidgetsBindingObserver; audio hooks
never autoplay on resume. No real audio assets ship in Stage 3 (AudioService
is a wired no-op facade).

## 2026-10-18 — Programmatic development art for Stage 3

TileArt CustomPainter renders shape+pattern markings (never colour-only) for
L03 tiles/reference and L01 slot outlines. Real illustration assets remain
missing per docs/ASSET_LIST.md; nothing here is presented as final art.
