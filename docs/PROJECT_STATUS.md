# Project Status — Tiny Repair Town

## Overnight completion — full recheck + all 20 levels + APK attempt (2026-10-18 ~03:35–04:35 PKT)

Per the owner's recheck directive ("audit everything, fix bugs, push the build as complete as possible by morning"), an overnight coordinator ran three workers and independently verified their output:

1. **Independent verification — all green** (re-ran by the coordinator, not just reported):
   - `dart test` (package root): **57/57 passed**
   - `dart analyze` (package root): no issues · `flutter analyze` (app/): no issues
   - `flutter test --concurrency=1` (app/): **17/17 passed**
   - Solver scripts `/tmp/solve_L02_L10.dart` (**248 checks, 0 fail**) and `/tmp/solve_L11_L20.dart`: **ALL CHECKS PASSED, exit 0** — every level loads via `Level.fromJson`, catalog-validates (no cycles, tiers correct), and is programmatically solved with the real engines.
2. **Full QA audit** of the app shell vs the master spec: **14 bugs found and fixed** — including 2 critical (Urdu toggle crashed the app: missing `flutter_localizations` delegates; save-recovery flag missed corrupt-primary-without-backup). Also implemented: the §9 inactivity hint pulse, a real parent gate (randomized press-and-hold, expires properly), `/level` route guard, chain progression replacing the Stage-3 showcase deviation, and wiring for dead settings (`largeText`, `extraGuidance`). Full list in QA_REPORT.md; all regression-tested.
3. **Stage 4 content — COMPLETE**: all 20 levels are now real (`stub:false`), authored per the launch table with unique compositions, en+ur strings, 3 hints each, stickers, map improvements, and a11y labels. L20 is a 3-stage finale (matchParts + buildOrder + restorePattern).
4. **APK: BLOCKED by sandbox network policy** — everything else is ready; the single remaining step is `flutter build apk --debug`. See below.

### APK blocker (verified with evidence, not a guess)
`flutter build apk --debug` fails because the Gradle daemon handshake (JVM→JVM over 127.0.0.1 TCP) is intercepted by the sandbox network policy:
- Gradle 9.3.1 distribution downloaded fine via curl (224MB; egress proxy works).
- The daemon starts, binds 127.0.0.1:<port>, listens and advertises — healthy per its own log.
- The client's first write fails: `MessageIOException: Could not write '/127.0.0.1:<port>'` caused by `java.io.IOException: Broken pipe`; the daemon never sees the client's connection.
- Ruled out: proxy env vars (reproduced with all unset), OOM (no dmesg kills; daemon RSS ~155MB), port conflicts, stale registry, heap size (8G→3G tried; daemon starts either way).
- Minimal repro: a bare-Java NIO SocketChannel to a local Python server gets its connection answered with the sandbox policy message *"muse: Other TCP connections is turned off for this assistant. To allow it, ask the user to open Muse"* — while Python→Python and curl→Python to the same address work. Conclusion: the sandbox intercepts JVM-originated loopback TCP, which the Gradle daemon handshake requires.
- No evasion attempted (platform policy). **Unblock:** allow TCP for the assistant per the policy message, then re-run `flutter build apk --debug`. First build will download ~350MB of Gradle/AGP deps (proxy already configured in `~/.gradle/gradle.properties`).
- Diagnostic changes made along the way were **reverted**: `android/gradle/wrapper/gradle-wrapper.properties` (temporarily `file://` distributionUrl) and `android/gradle.properties` (`-Xmx8G` lowered to `-Xmx3G` for this 7.7GB VM) are back to original. If the network block is lifted, lower the heap again before building here.

### Verification categories — overnight
- **Implemented and verified:** all 20 levels (solver-proven with the real engines), 14 audit bugfixes (regression-tested), save atomicity/recovery/migration, entitlement boundaries, parent gate, inactivity pulse, EN/UR + RTL, chain progression.
- **Implemented, not verified:** L20 finale multi-stage UI (falls back to "Unsupported puzzle type" — unreachable without entitlement; real screen is future work), interactive drag (tap-to-place tested; drag shares the engine path), on-device behavior.
- **Blocked by sandbox policy:** the debug APK itself — one command away once TCP is allowed.
- **Requires owner configuration:** Play Console account, app ID, product ID/price, keystore decisions, privacy policy, Urdu fluent review.

---

# Project Status — Tiny Repair Town (prior, kept for history)

Updated: 2026-10-18. Stages 1 (specify), 2 (playable L01) and 3 (app shell +
three playable systems) are complete to the extent this environment allows.
See `docs/QA_REPORT.md` for verification evidence.

## What was built (this handoff)

- **Stage 1 — Specify:** `docs/CONTENT_SCHEMA.md` (level + save JSON schema v1, the
  contract for everything), `ARCHITECTURE.md`, `ASSET_LIST.md`,
  `IMPLEMENTATION_CHECKLIST.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`.
- **Stage 2 — Playable L01:**
  - `lib/` — pure-Dart engines, zero Flutter dependency: `puzzles/match_parts.dart`,
    `puzzles/build_order.dart`, `puzzles/restore_pattern.dart`, `models/level.dart`
    (validation + availability/entitlement rules), `core/save_data.dart` (atomic
    writes, migration v1→v2, corrupt recovery), `core/localization.dart` (en/ur).
  - `assets/levels/` — 20 level JSONs. `level_L01.json` fully authored (Wobbly Toy
    Car, System A, 3 parts, drag + tap, tutorial, 3 hints, Little Wheel sticker,
    workshop map improvement). L02–L20 are scaffold stubs (`"stub": true`) with
    correct ids/tiers/systems per the launch table.
  - `test/` — 53 Dart unit tests, all passing (`dart test`).
  - `web-preview/l01_preview.html` — single-file, offline, playable L01 preview
    (dev only; not an Android build).

## Verification categories (per standing brief)

- **Implemented and verified:** 3 puzzle engines, level validation, availability/
  entitlement boundaries, idempotent rewards, save migration + corrupt recovery,
  localization tables, L01 content (solvable, validated), web preview structure.
- **Implemented, not verified:** web-preview *interactive* behavior (code-reviewed
  only; no headless browser here — open the file for a smoke test).
- **Simulated for development:** web preview as a stand-in for the Flutter UI.
- **Requires owner configuration:** Play product id/price, app id, privacy policy,
  billing verification service.
- **Blocked by unavailable tooling:** Flutter app shell, Android AAB/APK, on-device
  testing, Play billing test flow.

## Toolchain update — Stage 3a (Flutter install, 2026-10-18)

- **Flutter 3.47.7** (channel stable, framework revision `abaf9c5237`, 2026-10-08;
  Engine `d8a2d6c768`; Tools **Dart 3.13.5**, DevTools 2.60.0) installed at
  `~/workspace/.tooling/flutter` (owner-approved). Version verified against the
  official release index
  (`https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json`)
  at install time — 3.47.7 was current stable. Existing Dart CLI at
  `~/workspace/.tooling/dart-sdk/` untouched.
- `flutter doctor`: Flutter ✓. **Android toolchain ✗** (no Android SDK — explicitly
  out of scope, no APK/AAB possible). Chrome ✗ (no browser binary here).
  Linux desktop toolchain ✗ (no clang++/ninja/GTK). `flutter test` (VM) and
  `flutter build web` remain usable; device/emulator testing is not.
- Note: tarball extraction logged many `Cannot change ownership` warnings
  (archive uid 1000 not mappable in this sandbox); files extracted fine and
  `flutter --version`/`flutter doctor` run cleanly.

## Blockers for Stage 4 (updated 2026-10-18)

1. ~~No Flutter/Dart-for-mobile toolchain on this VM~~ — RESOLVED 2026-10-18
   (Flutter 3.47.7 installed; `flutter test`/`flutter build web` verified;
   Android SDK still absent by design — no APK/AAB possible).
2. No Android device/emulator — no on-device testing (unchanged).
3. Owner Play setup pending: `[FINAL_ANDROID_APPLICATION_ID]`,
   `[CONFIRMED_PLAY_PRODUCT_ID]`, `[OWNER_APPROVED_PRICE]`, Play Console account
   (unchanged).
4. Content: L02, L05–L20 still stubs (Stage 4 work). L01/L03/L04 fully authored.

## Exact next steps (Stage 4)

1. Author L02, L05–L10 real content (replace stubs); wire full chain
   progression via `AppState.isAvailableByChain` (already implemented, unused
   in Stage 3) and remove the showcase deviation.
2. Author final art/audio or record the missing-media register (see ASSET_LIST.md).
3. Get Urdu strings reviewed by a fluent speaker before calling localization final.
4. Replace `com.example` org with `[FINAL_ANDROID_APPLICATION_ID]` once the
   owner confirms it (recorded in DECISIONS.md).

## Stage 3 handoff — what was built (2026-10-18)

- **App shell** (`app/`, Flutter 3.47.7): `flutter create --project-name
  tiny_repair_town_app --org com.example --platforms=android,web app`.
  `com.example` is temporary scaffolding; real application ID is owner
  placeholder `[FINAL_ANDROID_APPLICATION_ID]`.
- **Single-source content:** app depends on the pure-Dart package as
  `tiny_repair_town: path: ../`; parent pubspec declares
  `flutter: assets: - assets/levels/`; levels load via
  `rootBundle.loadString('packages/tiny_repair_town/assets/levels/level_<ID>.json')`.
  Engines/JSON reused, never duplicated.
- **Content:** L03 "Patchwork Kite" (system C, 2x2, always-visible reference,
  shape+pattern tiles, sticker_happy_kite) and L04 "Picnic Wagon" (system B,
  3 steps with prerequisites, sticker_picnic_basket) fully authored with
  en/ur title/request/3 hints/tutorial/a11y; `test/level_test.dart` now expects
  L01+L03+L04 authored (rest stubs) with engine-driven solvability cases.
- **Playable now:** L01 (drag + tap-to-place, snap animation with engine input
  lock, tutorial overlay, 3 free hint strengths), L04 (step guide, tap parts,
  gentle wrong-tap cue, never resets), L03 (always-visible reference, tap or
  drag tiles, free replacement). Home → town map → level → celebration;
  celebration awards the sticker idempotently and shows the map improvement.
- **Shell features:** pause/resume (Back closes overlay first, then pauses;
  checkpoint on pause), lifecycle observer (pause on background, never autoplay
  audio on resume; no real audio assets yet), EN/UR toggle with RTL (progress
  preserved), reduced-motion support, ≥56px touch targets, no timers, gentle
  incorrect handling, hints always free. Parents route is an honest placeholder
  (full gate/settings/purchases land in Stage 6).
- **Persistence:** `PathProviderSaveStorage` (real app) / `MemorySaveStorage`
  (tests); checkpoints at level start, pause, completion.
- **Showcase deviation (documented in DECISIONS.md):** L01/L03/L04 directly
  playable; all other levels show neutral "More activities in Parents" locked
  state. Full chain progression (`AppState.isAvailableByChain`) lands in Stage 4.

## Verification categories (per standing brief) — Stage 3

- **Implemented and verified:** pure-Dart engines + 55 unit tests green;
  L01/L03/L04 content validation + solvability; `flutter analyze` clean;
  6 Flutter widget tests green (L01/L04/L03 completion journeys, pause/resume
  checkpoint, locked-level neutrality); `flutter build web` succeeds.
- **Implemented, not verified:** interactive drag behavior (widget tests cover
  tap-to-place; drag uses the same engine path), RTL Urdu layout rendering,
  background-pause on a real device, `PathProviderSaveStorage` on Android
  (path_provider unresolved on-device here).
- **Simulated for development:** programmatic TileArt (dev assets, not final
  art); `flutter build web` output (dev artifact — never an Android build).
- **Requires owner configuration:** `[FINAL_ANDROID_APPLICATION_ID]`,
  Play product/price, privacy policy, billing verification service.
- **Blocked by unavailable tooling:** Android SDK (no APK/AAB), on-device
  testing, Play billing test flow.

## Run instructions

- Pure-Dart tests: `~/workspace/.tooling/dart-sdk/bin/dart test` from
  `~/workspace/tiny-repair-town/` (55/55 green).
- App: `flutter analyze` (clean), `flutter test --no-pub --concurrency=1`
  from `~/workspace/tiny-repair-town/app/` (6/6 green; note the
  rootBundle/setUpAll quirk in QA_REPORT.md).
- Web (dev only): `flutter build web` from `app/` — succeeds; not an Android build.
