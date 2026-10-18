# QA Report — Tiny Repair Town, Stages 1–2

Date: 2026-10-18. Environment: Ubuntu 24.04 VM (x86_64), Dart SDK 3.13.5
(`~/workspace/.tooling/dart-sdk/`), Python 3.12, Node 24. No Flutter, no Java,
no Android SDK, no device/emulator, no headless browser.

## Toolchain change (Stage 3a, 2026-10-18)

Flutter 3.47.7 stable installed at `~/workspace/.tooling/flutter`
(verified against the official release index at install time; Tools Dart 3.13.5).
`flutter doctor`: Flutter ✓; Android toolchain ✗ (no Android SDK — out of scope);
Chrome ✗; Linux desktop toolchain ✗. `flutter test` and `flutter build web` usable.

An unexecuted test is "not run", not "passed".

## Automated checks — RAN

| # | Command | Result |
|---|---|---|
| 1 | `dart pub get` | OK — dependencies resolved (`test ^1.25.0` only) |
| 2 | `dart analyze` | OK — **No issues found** |
| 3 | `dart test` | OK — **53/53 passed** (5 files, ~2.6 s) |
| 4 | Python JSON check over `assets/levels/*.json` | OK — 20 files, 20 unique ids L01–L20 |
| 5 | `node --check` on extracted preview `<script>` | OK — no syntax errors |
| 6 | Structural grep on `l01_preview.html` (balanced tags, no external URLs) | OK — 0 external references |

### Test coverage (what the 53 tests actually assert)

- **match_parts (11):** correct snap + input lock during animation; wrong part →
  gentle return with no state change; matching by part id not color/shape;
  orientation gating + 90° rotation only when allowed; one piece ≠ two slots;
  filled-slot rejection; distractor matches nothing; snap-radius respect;
  unknown ids safe; reset for replay.
- **build_order (8):** dependency-order completion; wrong sequence → hint cue,
  never resets progress; re-select = already_done; unknown part safe; multiple
  valid next steps when authored; diamond prerequisites (L15 style); completed
  steps stay visible; reset.
- **restore_pattern (8):** full-solution completion; authored alternative accepted;
  wrong tile placed but replaceable without penalty; completion only on actual
  conditions; clearCell; unknown ids safe; shape+pattern markings present; reset.
- **level (12):** 20 unique ids; tiers match launch table; catalog has no missing
  prereqs/cycles; L01 playable + others stub-flagged; L01 validates clean;
  puzzle types match plan; no remote URLs. Availability: L01 always; chain rule
  (Ln needs L(n−1)); pack boundary (L11/L20 need L10/L19 **and** entitlement);
  entitlement never skips prerequisites.
- **save_data (8):** fresh defaults; idempotent completeLevel (no dup stickers
  across 5 save/load cycles); serialized concurrent saves; corrupt primary →
  backup fallback; both corrupt → flagged fresh defaults, no crash; v1→v2
  migration adds `extraGuidance=false` preserving data; language round-trip;
  `resetProgress` keeps purchase entitlement.
- **localization (6):** spec §13 sample strings; ur=RTL; fallback en→key; every
  key has non-empty en+ur; gameplay strings present.

## Checks — NOT RUN

- Web-preview interactive behavior (drag/tap, hints, celebration, RTL layout) —
  no headless browser on this VM; code-reviewed only. **Recommended:** open
  `web-preview/l01_preview.html` in a real browser as a smoke test.
- Flutter widget/integration tests — no Flutter toolchain.
- On-device testing (phone/tablet, rotation, TalkBack, audio) — no device.
- Play billing flows — no Play setup; billing is interface-only at this stage.
- Child usability testing — not arranged (and never without parent permission).

## Known issues (summary; full list in KNOWN_ISSUES.md)

1. **Blocker:** no Android toolchain → no AAB/APK; Stage 3+ needs a Flutter machine.
2. **Blocker:** L02–L20 are stubs, not playable content (Stage 4 work).
3. Final art and recorded narration are missing (programmatic placeholders only).
4. Urdu strings are drafted, not reviewed by a fluent speaker.
5. Purchase verification is unimplemented beyond a local entitlement cache
   (correctly never treated as secure).

## Honesty notes

- The web preview is a **development preview only**; it does not establish Android
  compatibility or billing behavior. It says so in its own footer.
- One real bug was caught during this stage: the tap-to-place handler in the
  preview deselected pieces before slot clicks registered — fixed and guarded.
- One environment failure: `/tmp` (512 MB tmpfs) filled during the Dart SDK
  download; recovered by moving the SDK to `~/workspace/.tooling/`. Logged in
  `docs/IMPROVEMENT_LOG.md`.

---

# QA Report — Stage 3 (2026-10-18)

Environment: Ubuntu 24.04 VM (x86_64), Flutter 3.47.7 stable
(`~/workspace/.tooling/flutter`, Tools Dart 3.13.5), Dart SDK 3.13.5 CLI.
`flutter doctor`: Flutter ✓; Android toolchain ✗ (no Android SDK — out of
scope); Chrome ✗; Linux desktop toolchain ✗.

An unexecuted test is "not run", not "passed".

## Automated checks — RAN

| # | Command (from repo root unless noted) | Result |
|---|---|---|
| 1 | `dart test` (parent pure-Dart package) | OK — **55/55 passed** (53 carried + 2 net new: authored-level + solvability cases) |
| 2 | `flutter analyze` (from `app/`) | OK — **No issues found** |
| 3 | `flutter test --no-pub --concurrency=1 --reporter expanded` (from `app/`) | OK — **6/6 passed** (5 widget journeys + smoke) |
| 4 | `flutter build web --no-pub` (from `app/`) | OK — `build/web` produced (dev artifact only) |
| 5 | `Level.validate()` on L03/L04 JSON | OK — zero errors (run inside `dart test`) |
| 6 | Engine solvability cases (L01 via MatchPartsEngine, L03 via RestorePatternEngine, L04 via BuildOrderEngine) | OK — all complete through the real engines |

### What the 6 app tests assert

- **L01 journey:** home → town → request → tutorial(skip) → tap-place all 3
  parts → celebration → `sticker_little_wheel` in save, `completedLevels`
  contains L01, replay idempotent (no duplicate sticker), town map shows the
  workshop improvement entry.
- **L04 journey:** wrong-order tap first (gentle, no progress) → correct order
  (wheels→bed→handle) → celebration → `sticker_picnic_basket` recorded.
- **L03 journey:** reference strip present, 4 cells start empty → tap tile+cell
  ×4 → celebration → `sticker_happy_kite` recorded.
- **Pause/resume:** place 1 piece → system Back → pause dialog (not instant
  exit) → Resume keeps piece → Back-to-town → re-enter → checkpoint restored
  the placed piece; L01 not marked complete.
- **Locked neutrality:** L02 etc. show "More activities in Parents", no price
  button; L01/L03/L04 chips directly playable.

### Real bugs caught by tests this stage

1. **Slot overlap on small screens** (fixed): L01 slots sized at 22% of width
   overlapped vertically (roof/window 0.20 apart), so taps hit the wrong slot.
   Fix: slot size now derives from the smallest pairwise slot distance
   (×0.8, clamped 56–140px) — no overlap for any authored content.
2. **Test key mismatches** (fixed): test used `slot_part_wheel`/`cell_tile_red_star`
   instead of `slot_slot_wheel`/`cell_cell_0_0`.
3. **Async completion→navigation timing** (fixed): celebration navigation runs
   after the async `completeLevel`; tests now pump 1s before asserting.

### Environment/test-harness quirks (documented, not app bugs)

- `flutter test` runs test *files* concurrently by default; on this VM that
  starved the software renderer. Use `--concurrency=1`.
- A second `rootBundle.loadString` sequence inside a later `testWidgets` test
  never completes on this VM (first test's loads work). Workaround: load the
  immutable level catalog once in `setUpAll` and share it; each test still gets
  a fresh `AppState` + `MemorySaveStorage`.
- Pipe `flutter test` output to a file and tail the file; `| tail` hides all
  progress until the run ends.

## Checks — NOT RUN

- Drag-gesture completion (widget tests cover tap-to-place; drag uses the same
  `tryPlace`/`nearestSlot` engine path — drag itself not exercised).
- Urdu RTL rendering inspection, TalkBack/semantics audit, palette contrast
  measurement — no device, no screen inspection possible here.
- `PathProviderSaveStorage` on Android (needs device/emulator).
- Background/resume lifecycle on a real OS (only the observer wiring exists).
- On-device performance (fps, cold start, download size).
- Play billing flows — no Play setup; commerce untouched in Stage 3.
- Child usability testing — not arranged.

## Known issues (summary; full list in KNOWN_ISSUES.md)

1. **Blocker:** no Android SDK → no APK/AAB (out of scope by owner decision).
2. **Blocker:** L02, L05–L20 still stubs (Stage 4).
3. Programmatic TileArt is development art, not final illustration.
4. No audio assets; AudioService is a wired no-op facade.
5. Urdu strings drafted, not reviewed by a fluent speaker; no bundled Urdu font yet.
6. Parent area is an honest placeholder (Stage 6).

## Honesty notes

- `flutter build web` output is a **development artifact only**; it does not
  establish Android compatibility, performance, or billing behavior.
- The `com.example` org / application ID is temporary scaffolding; the real ID
  is the owner placeholder `[FINAL_ANDROID_APPLICATION_ID]`.
- Stage 3 deliberately exposes L01/L03/L04 directly (documented showcase
  deviation); full chain progression lands in Stage 4.

---

# QA Report — Overnight completion (2026-10-18 ~03:35–04:35 PKT)

Environment: Ubuntu 24.04 VM (x86_64), Flutter 3.47.7 stable, Temurin JDK 17.0.20.1,
Android SDK 36.0.0 (cmdline-tools 23.0, platform-tools 37.0.1, build-tools 36.0.0,
licenses accepted; `flutter doctor` Android toolchain ✓).

## Automated checks — RAN (coordinator-verified)

| # | Command | Result |
|---|---|---|
| 1 | `dart test` (package root) | **57/57 passed** |
| 2 | `dart analyze` (package root) | No issues found |
| 3 | `flutter analyze` (app/) | No issues found |
| 4 | `flutter test --concurrency=1` (app/) | **17/17 passed** (11 widget journeys + 5 pulse unit + smoke) |
| 5 | `/tmp/solve_L02_L10.dart` (Dart SDK + project package config) | **248 checks, 0 fail, exit 0 — ALL CHECKS PASSED (L02..L10)** |
| 6 | `/tmp/solve_L11_L20.dart` (same) | **ALL CHECKS PASSED, exit 0** |
| 7 | `flutter build apk --debug` | **BLOCKED** — sandbox network policy (evidence below), not an app bug |

Checks 5–6 verified per level: `Level.fromJson` + `Level.validate()` clean,
`validateCatalog` over all 20 (no cycles, tiers correct), `stub:false`,
en+ur non-empty on every string (recursive walk), exactly 3 hints with
strengths 1,2,3, no `http` anywhere, and programmatic solves with the real
engines — including L11/L17 rotation, L15's two-prerequisite step, L16 decoy
rejection, L20's three stages in order, L04's wrong-first-tap gentleness, and
L07's distractor rejection.

## Bugs found and fixed (14 — auditor report, all green after)

1. **Urdu toggle crashed the app (critical).** `MaterialApp` set `locale: ur`
   with no `localizationsDelegates`. Fixed: added `flutter_localizations` +
   global delegates in `main.dart`. Regression-tested: RTL in Urdu, LTR in
   English, progress preserved across toggle.
2. **Save recovery flag missed corrupt-primary-without-backup (critical).**
   Flag formula required a corrupt backup; a missing backup silently reset the
   child. Fixed in `save_data.dart`; old test corrected + regression test added.
3. Stale content-snapshot test vs newly authored levels — converted to a
   stage-proof contract test.
4. **Inactivity hint pulse missing (spec §9).** New `widgets/inactivity_pulse.dart`:
   pulses once after ~10s idle; suppressed while a menu is open, an animation
   blocks input, audio plays, or the app is backgrounded. Wired into all three
   puzzle screens. 5 new unit tests.
5. Hint-button taps didn't reset the inactivity window (AppBar button was
   outside the reset `Listener`) — `_pulse.reset()` added in all three screens.
6. **Parent area was a stub with no gate (spec §17).** Implemented:
   written instruction + randomized 2–4s press-and-hold (re-rolled per
   attempt); honest "not identity verification" copy; expires on background,
   relaunch, and 2-min inactivity. Behind the gate: settings, progress
   summary, neutral full-game info (no purchase button — billing is
   interface-only), privacy note, reset-with-confirmation that preserves the
   entitlement (test-covered).
7. `/level` route bypassed chain/entitlement locks — `LevelScreen` now
   re-checks `isPlayableNow` and shows the neutral locked state.
8. Stage-3 showcase rule blocked authored free levels — replaced with the
   chain rule (`Level.isLevelAvailable`); widget tests updated to play the chain.
9. First-run language picker was non-dismissible — now dismissible.
10. Hardcoded screen-reader labels — localized (`slotSemantic`/`panelSemantic`).
11. Dead settings (`largeText`/`extraGuidance`) — now functional (1.3× text
    scaler; persistent extra-guidance highlight in match-parts/restore-pattern).
12. Entitlement flag not marked cache-only — documented as local cache, never
    purchase verification (spec §18).
13. `AudioService` lacked `isPlaying` for the §9 suppression rule — honest
    always-false getter until Stage 5 playback lands.
14. Stray non-functional "Close" label on the celebration screen — removed.

## The APK blocker — evidence log

`flutter build apk --debug` cannot complete in this sandbox. Diagnosis:
- Gradle 9.3.1 downloaded via curl (224MB, proxy OK); installed via a temporary
  `file://` distributionUrl (reverted afterward).
- Daemon starts, binds 127.0.0.1:<port>, listens, advertises — healthy per its
  own log. Client fails at first write: `MessageIOException: Could not write
  '/127.0.0.1:<port>'` ← `java.io.IOException: Broken pipe`. Daemon never
  sees the client's connection.
- Ruled out: proxy env vars (reproduced with all unset), OOM (no dmesg kills;
  daemon RSS ~155MB), port conflicts, stale daemon registry (wiped each run),
  heap size (`-Xmx8G`→`-Xmx3G` tried; daemon starts either way), DNS (literal
  IPs used throughout).
- Minimal repro: bare-Java NIO `SocketChannel` → local Python server gets the
  connection answered with the sandbox policy message *"muse: Other TCP
  connections is turned off for this assistant. To allow it, ask the user to
  open Muse"*; Python→Python and curl→Python to the same address work fine.
  Conclusion: the sandbox intercepts JVM-originated loopback TCP, which the
  Gradle daemon handshake requires.
- No evasion attempted (platform policy). **Unblock:** allow TCP for the
  assistant per the policy message, then re-run `flutter build apk --debug`
  (first build downloads ~350MB of Gradle/AGP deps; proxy already configured
  in `~/.gradle/gradle.properties`). Lower `org.gradle.jvmargs` from `-Xmx8G`
  for this 7.7GB VM before building.

## Checks — NOT RUN

- The APK itself (blocked — see above). Everything leading up to it is verified.
- L20 finale multi-stage UI (falls back to "Unsupported puzzle type";
  unreachable without entitlement — no purchase flow exists yet).
- On-device testing (no device/emulator), TalkBack, performance measurements.
- Play billing flows (no Play setup). Urdu fluent review. Final art/audio.
- Child usability testing — not arranged.

## Honesty notes (overnight)

- The debug APK was **not produced**; nothing here should be read as "build
  ready". The one-line unblock and the exact failing command are documented
  above so the morning retry is mechanical.
- All 20 levels are real, validated, solver-proven content — but art is still
  programmatic placeholders, audio is a wired no-op, and Urdu is draft.
- The two solver scripts live in `/tmp` (ephemeral); the checks they ran are
  recorded above. Re-running them requires re-creating equivalent checks.
