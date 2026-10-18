# Implementation Checklist — Tiny Repair Town

2026-10-18. Grouped by spec §23 stages. ✅ = delivered in workspace (Stages 1–2).
Items assigned to a sibling agent but not yet visible in the workspace are marked
⚠️ explicitly rather than checked.

## Stage 2 — Build one complete playable level

- ✅ Environment inspection recorded (Ubuntu 24.04; no Flutter/Java/Android SDK;
  Dart 3.13.5 at `~/workspace/.tooling/dart-sdk/bin/dart`; Python 3.12, Node 24;
  ~7.5G disk free).
- ✅ Content schema v1 authored: `docs/CONTENT_SCHEMA.md` (proportional coords,
  3 hint strengths, finale as composed stages, save schema v2).
- ✅ 20 level JSONs in `assets/levels/`: L01 fully authored (`stub: false`),
  L02–L20 scaffold stubs (`stub: true`) with correct ids/tiers/types/counts.
- ⚠️ Pure-Dart engines (matchParts/buildOrder/restorePattern) — assigned to
  sibling agent; `lib/{core,models,puzzles}/` still empty dirs, not yet landed.
- ⚠️ Save system (atomic write, migration, corrupt recovery) — assigned to
  sibling agent; not yet landed in workspace.
- ⚠️ Localization tables (en/ur) — assigned to sibling agent; not yet landed.
- ⚠️ Web preview of L01 — assigned to sibling agent; `web-preview/` empty, not
  yet landed.
- ⚠️ Unit tests — written by sibling agent; not yet visible; results belong in
  QA_REPORT.md (parent agent).

## Stage 3 — Complete the three puzzle systems (all unchecked)

- [ ] Reusable content loader + content validator (solvability, cycle, tier checks).
- [ ] One representative playable level each for systems A, B, C (beyond L01).
- [ ] Hint system (3 strengths; gentle pulse after ~10s inactivity).
- [ ] Pause/resume + lifecycle handling (background, rotation, audio interrupt).
- [ ] Flutter app shell (needs Flutter toolchain — currently unavailable).
- [ ] Android project scaffold (needs Android SDK — currently unavailable).

## Stage 4 — Author all twenty levels (all unchecked)

- [ ] Full authoring of L02–L20 (configs, hints, requests, validation cases).
- [ ] Clear `"stub": true` from all stubs; none remain unplayable.
- [ ] Dependency validation across all 20 levels.
- [ ] All 20 stickers + map improvements wired to completions.
- [ ] Both completion celebrations (Starter Street L10, full-town L20/picnic).

## Stage 5 — Finish interface, localization and media (all unchecked)

- [ ] Final art for every row in `docs/ASSET_LIST.md` (currently all missing).
- [ ] Adaptive phone/tablet layouts, rotation, safe areas.
- [ ] English/Urdu UI complete; Urdu shaping/RTL reviewed by fluent speaker.
- [ ] Voice scripts authored; narration recorded + reviewed (audio missing list).
- [ ] Audio controls (music/effects/narration), reduced-motion support.
- [ ] Accessibility pass (TalkBack, touch targets ≥56dp, semantic labels).

## Stage 6 — Parent area and commerce (all unchecked)

- [ ] Parent gate (not a checkbox; no simple arithmetic as guarantee; no plaintext PIN).
- [ ] Parent dashboard: settings, progress summary, reset-with-confirmation.
- [ ] Real billing integration behind the entitlement interface; product lookup,
  pending/canceled/failed states, restore, revocation handling.
- [ ] Production verification service per spec §18 (owner setup required:
  [CONFIRMED_PLAY_PRODUCT_ID], [OWNER_APPROVED_PRICE], verification config).
- [ ] Reset progress keeps purchase ownership.

## Stage 7 — QA and release packaging (all unchecked)

- [ ] Test matrix from spec §§21–22 executed; QA_REPORT.md with real results.
- [ ] On-device phone + tablet inspection; performance measured (60fps, ≤5s start, <100MB).
- [ ] Android AAB (+ test APK) built and signed status stated — BLOCKED, no toolchain.
- [ ] Store materials: icon 512×512, feature graphic 1024×500, real screenshots.
- [ ] Privacy policy draft + data inventory matching implementation.
- [ ] Play Console submission checklist; owner handoff with §25 placeholders
  ([DEVELOPER_OR_BUSINESS_NAME], [SUPPORT_EMAIL],
  [PUBLIC_PRIVACY_POLICY_HTTPS_URL], [FINAL_ANDROID_APPLICATION_ID],
  [PLAY_CONSOLE_ACCOUNT_TYPE_AND_STATUS]).
