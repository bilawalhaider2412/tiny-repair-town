# Improvement Log

Failure → root cause → fix → evidence → prevention rule. Workflow notes only.

## 2026-10-18 — /tmp filled during Dart SDK download

- **Failure:** heredoc write to /tmp failed with "No space left on device"; Dart
  SDK unzip into /tmp also at risk.
- **Root cause:** /tmp is a 512 MB tmpfs; the ~228 MB SDK zip plus unzip output
  exceeded it.
- **Fix:** moved the SDK zip to `~/workspace/.tooling/` (persistent overlay disk,
  7.5 GB free) and unzipped there; Dart 3.13.5 verified working.
- **Evidence:** `dart --version` → 3.13.5; `dart test` 53/53 pass.
- **Prevention rule:** never download/unzip large toolchains into /tmp on this VM;
  use `~/workspace/.tooling/` for persistent tool installs.

## 2026-10-18 — Widget tests hung after the first test (rootBundle quirk)

- **Failure:** `flutter test` on `app/test/app_test.dart` hung indefinitely at
  the second test; a bisection repro proved the second `rootBundle.loadString`
  sequence inside a later `testWidgets` test never completes on this VM (the
  first test's loads work fine).
- **Root cause:** environment/test-harness quirk with repeated rootBundle asset
  loads across `testWidgets` tests (exact channel mechanism unidentified).
- **Fix:** load the immutable level catalog once in `setUpAll` and share it;
  each test still gets a fresh `AppState` + `MemorySaveStorage` so progress
  stays isolated.
- **Evidence:** full suite then ran 6/6 green.
- **Prevention rule:** in widget tests, load immutable bundle assets once per
  file in `setUpAll`; keep per-test state (save stores, controllers) fresh.

## 2026-10-18 — `flutter test` runs test files concurrently by default

- **Failure:** full-suite runs stalled with multiple `flutter_tester` processes
  starving each other on this 2-core VM.
- **Root cause:** `flutter test` shards test *files* across processes unless
  told otherwise.
- **Fix:** `flutter test --concurrency=1` on this VM.
- **Evidence:** suite completed after the flag; single-file runs were unaffected.
- **Prevention rule:** on constrained VMs, always pass `--concurrency=1` and
  pipe test output to a file (tail it) instead of `| tail`, which hides all
  progress until the run ends.

## 2026-10-18 — L01 slots overlapped on small screens (real layout bug)

- **Failure:** widget test tap on `slot_slot_window` missed — hit-test landed
  on the overlapping `slot_roof` area.
- **Root cause:** slots sized at 22% of work-area width while two slots sat
  0.20 of the height apart; on short viewports they overlapped.
- **Fix:** slot size now derives from the smallest pairwise slot distance
  (×0.8, clamped 56–140px), so authored slots can never overlap.
- **Evidence:** `flutter test` L01 journey green after the fix.
- **Prevention rule:** size proportional drop targets from content geometry,
  not from one axis alone; keep the widget test that taps every slot.

## 2026-10-18 — Celebration navigation needs a pump after async completion

- **Failure:** tests asserting the celebration screen failed intermittently.
- **Root cause:** `_onComplete` awaits the async `completeLevel` save before
  navigating; a single `tester.pump()` did not flush the microtask chain.
- **Fix:** `await tester.pump(const Duration(seconds: 1))` after the final
  puzzle action (never `pumpAndSettle` — the celebration animation repeats).
- **Evidence:** 6/6 green.
- **Prevention rule:** after any async-completion → navigation flow in tests,
  pump a fixed duration; reserve `pumpAndSettle` for screens with no looping
  animations.

## 2026-10-18 — `pkill -f` matched the invoking shell

- **Failure:** `pkill -f "flutter_tester"` SIGTERM'd the agent's own exec
  session because the pattern appeared in its own command line.
- **Root cause:** `pkill -f` matches the full command line, including the
  caller's.
- **Fix:** use the bracket trick (`pkill -f "flutter_teste[r]"`) so the
  pattern cannot match the invoking command.
- **Prevention rule:** never `pkill -f` with a literal pattern that appears in
  the same command; use the `[x]` character-class form.

## 2026-10-18 — Urdu toggle crashed: missing localization delegates (QA audit)

- **Failure:** switching the app language to Urdu crashed with "No
  MaterialLocalizations found"; the Urdu toggle was completely broken and the
  Stage 3 builder's "everything verified" missed it (no test ever toggled).
- **Root cause:** `MaterialApp` set `locale: Locale('ur')` but never provided
  `localizationsDelegates`; only the default English delegates were present.
- **Fix:** added `flutter_localizations` (SDK package) and the three global
  delegates to `MaterialApp` in `app/lib/main.dart`.
- **Evidence:** new widget test "Urdu: RTL directionality; toggle preserves
  progress" failed before the fix, passes after; `flutter test` 17/17 green.
- **Prevention rule:** every locale the app advertises in `supportedLocales`
  must be exercised by at least one widget test that actually selects it.

## 2026-10-18 — Save recovery flag missed corrupt-primary + missing-backup (QA audit)

- **Failure:** a corrupt `save.json` with no `.bak` yet (only one save ever
  written) silently reset the child to defaults with `recoveredFromCorrupt`
  false — progress loss was not surfaced.
- **Root cause:** the flag formula was `primaryCorrupt && backupCorrupt`; a
  missing backup is not "corrupt", so the case fell through.
- **Fix:** `lib/core/save_data.dart` now flags recovery when the primary was
  corrupt and no usable backup existed; corrected the old test (which had
  asserted the silent-loss behavior) and added a regression test.
- **Evidence:** `dart test` 57/57 green, including the new
  "corrupt primary with missing backup -> defaults, flagged, no crash" test.
- **Prevention rule:** recovery-flag tests must cover the missing-file cases,
  not just the corrupt-file cases.

## 2026-10-18 — Stale snapshot test rotted as content landed (QA audit)

- **Failure:** `test/level_test.dart` asserted "L01/L03/L04 authored, all
  others stubs" — it broke the moment the content agent authored L02/L05/…
- **Root cause:** the test pinned a point-in-time content snapshot instead of
  the contract.
- **Fix:** replaced with a stage-proof contract test (every level validates;
  stubs never playable; non-stubs fully specified) plus a pin that the three
  system showcases stay authored.
- **Evidence:** `dart test` 57/57 green against the now-fully-authored catalog.
- **Prevention rule:** never assert transient content states (stub sets,
  tutorial flags) in tests; assert the schema contract instead.

## 2026-10-18 — Inactivity hint pulse was never implemented (QA audit)

- **Failure:** spec §9 requires the hint button to pulse once after ~10 s of
  inactivity; no such code existed in any puzzle screen.
- **Root cause:** missed in Stage 3; nothing in the test suite looked for it.
- **Fix:** new `InactivityPulse` helper + `PulsingHintButton` wired into all
  three puzzle screens (fires once; deferred while menus/animations/audio/
  background suppress it; static ring under reduced motion).
- **Evidence:** 5 unit tests + 2 widget tests; `flutter test` 17/17 green.
- **Prevention rule:** audit checklists need one test per spec "must/should"
  behavior, not just per screen.

## 2026-10-18 — Hint-button taps didn't reset the inactivity window (QA audit)

- **Failure:** new test "interaction resets the window" failed: tapping the
  hint button (in the AppBar, outside the body's pointer Listener) never
  reset the 10 s timer.
- **Root cause:** the reset Listener only wrapped `Scaffold.body`; AppBar
  actions were outside it.
- **Fix:** `_onHint()` in all three puzzle screens now calls
  `_pulse.reset()` explicitly.
- **Evidence:** the failing test passes; full suite green.
- **Prevention rule:** inactivity tracking must reset on every explicit user
  action handler, not only on a body-level pointer listener.

## 2026-10-18 — Parent area was an honest stub, gate missing (QA audit)

- **Failure:** spec §17 requires an adult-action parent gate with expiry;
  `ParentsScreen` was a placeholder with no gate at all.
- **Root cause:** deferred to "Stage 6" in Stage 3.
- **Fix:** implemented the gate (randomized 2–4 s press-and-hold, re-rolled
  per attempt; expires on background/relaunch/2-min inactivity) with
  settings, progress summary, neutral full-game info (no purchase button),
  privacy note, and reset-with-confirmation preserving the entitlement.
- **Evidence:** widget test covers hold-unlock, background relock, and
  reset-keeps-entitlement; `flutter test` 17/17 green.
- **Prevention rule:** spec-checklist items marked "later stage" need an
  explicit owner decision before a release build, not a silent stub.

## 2026-10-18 — `/level` route bypassed chain/entitlement locks (QA audit)

- **Failure:** `onGenerateRoute` built `LevelScreen` for any level id without
  checking availability — a direct route push could open a locked level.
- **Root cause:** availability was only enforced by which chips the town map
  rendered.
- **Fix:** `LevelScreen` now re-checks `AppState.isPlayableNow` and shows the
  neutral "More activities in Parents" state for locked levels.
- **Evidence:** new widget test "Direct /level navigation cannot bypass
  locks" passes.
- **Prevention rule:** every route that takes an id argument must re-validate
  authorization at the route layer, not just in the listing UI.
