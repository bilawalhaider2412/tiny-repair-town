# Architecture — Tiny Repair Town

Status: 2026-10-18 (Stages 1–3). Concise overview of how the code and content fit together.

## Guiding decisions

- **Puzzle logic is pure Dart with zero Flutter dependency.** Engines take content
  config + player input, emit immutable state updates. This lets all rules run and
  be unit-tested with the Dart VM alone (which is what this environment has),
  without waiting for a Flutter/Android toolchain. Flutter arrives later as a
  thin rendering and input shell.
- **Content-driven levels.** All 20 levels are versioned JSON in
  `assets/levels/` per `docs/CONTENT_SCHEMA.md` (schema v1). No puzzle tuning is
  hardcoded in Dart; the validator is the contract.
- **Billing sits behind an interface.** Gameplay queries an `EntitlementStore`
  abstraction. The production Play implementation and the dev mock both live
  behind it; gameplay code never branches on the billing implementation and never
  consults a local boolean as proof of purchase (per spec §18, production
  verification is server-side).
- **Offline-first.** Everything needed to play the free 10 levels (content, art,
  audio, fonts, save) ships in the bundle. No network call is on the free-game
  path; entitlement cache degrades gracefully offline.

## Module map (target layout per spec §15)

| Area | Role |
|---|---|
| `app/lib/` | Flutter app shell — **BUILT in Stage 3**: theme, routing, town map, three puzzle screens, celebration, parents placeholder, `AppState`, `PathProviderSaveStorage`/`MemorySaveStorage`, `LevelRepository` (rootBundle), audio hooks |
| `lib/core/` | Shared models, save-data layer, audio helpers, lifecycle (pure-Dart parts done; Flutter lifecycle observer lives in `app/lib/main.dart`) |
| `lib/features/puzzles/` | The three engines + validators + input controls — engines done (pure-Dart); Flutter input controls live in `app/lib/screens/puzzles/` |
| `lib/features/town/` | Map and improvement layers — Flutter town map done (`app/lib/screens/town_map_screen.dart`); improvement *art* still missing |
| `lib/features/progress/` | Checkpoints, unlocks and rewards — done via `SaveStore` + `AppState` |
| `lib/features/stickers/` | Collection + replay navigation — sticker award done; sticker *book* screen is Stage 4+ |
| `lib/features/parents/` | Gate, settings, reset (Stage 6; honest placeholder route exists) |
| `lib/features/billing/` | Purchase state, verification adapter, entitlement (interface only now) |
| `assets/levels/` | 20 level JSONs, schema v1 (L01, L03, L04 authored; L02, L05–L20 stubs) |
| `assets/art/`, `assets/audio/`, `assets/fonts/` | NOT YET POPULATED — all placeholders (Stage 3 uses programmatic TileArt) |
| `app/test/` | Widget tests (6 green) |
| `test/` | Pure-Dart unit + validation tests (55 green) |
| `integration_test/` | Device flows incl. billing test track (Stage 7) |
| `tools/` | Content validator, asset checks (planned) |
| `docs/` | Specs, QA, release (this tree) |

Current actual state: `lib/{core,models,puzzles}/` are pure-Dart and complete;
`app/` is the Flutter shell (Android + web platforms scaffolded, no Android SDK
here). `android/` exists only as `flutter create` scaffolding — it has never
been built.

## State management (single approach)

**Per-feature ChangeNotifier stores, no third-party state-management package.**
Each feature (puzzle session, town, settings, billing) owns one notifier holding
plain-Dart state; the engine remains a separate pure-Dart object the store drives.
Justification: zero extra dependencies for an offline kids' app, Flutter-native,
easy to test against the engine without widgets, and simple enough that the
parent-gate and billing state stay obviously separate from gameplay.

## Save-data design

- JSON file, schema v2 (`saveSchemaVersion: 2`), see `CONTENT_SCHEMA.md`.
- **Atomic writes:** write temp file → `fsync` → rename; keep a `.bak` copy of
  the last good save. Corrupt primary + corrupt backup → boot fresh defaults
  with `recoveredFromCorrupt: true` surfaced to the user, never a crash.
- **Migrations:** v1 → v2 adds `accessibility.extraGuidance` (default `false`).
  Never duplicate stickers on migration or replay; stickers are a set.
- **Checkpoints** saved at stable boundaries (level start, each finale stage,
  puzzle pause). Entitlement cache is separate from gameplay progress; resetting
  progress must not erase purchase ownership (Stage 6).

## Flutter app shell — BUILT in Stage 3 (2026-10-18)

The shell exists at `app/` (Flutter 3.47.7): theme with the spec palette,
named routing (home → town → level → celebration, plus parents placeholder),
the town map with five locations, one screen per puzzle system, pause/resume
with checkpoints, lifecycle handling, EN/UR with RTL, reduced-motion support,
and `PathProviderSaveStorage` for real persistence. The Android project is
`flutter create` scaffolding only — never built (no Android SDK on this VM,
out of scope). `flutter build web` succeeds as a dev artifact; per spec §1 it
establishes nothing about Android compatibility or billing.
