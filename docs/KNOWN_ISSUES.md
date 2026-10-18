# Known Issues — Tiny Repair Town

Honest list of defects, gaps and risks as of 2026-10-18. Severity:
**blocker** (stops a stage/release), **major** (core feature unusable),
**minor** (quality gap). "Unblocked by" names the stage/dependency that
resolves it.

## Blockers

- **APK build blocked by sandbox network policy (overnight 2026-10-18).**
  Android SDK 36.0.0 + Temurin JDK 17 are installed and `flutter doctor` is
  green, but `flutter build apk --debug` fails: the sandbox intercepts
  JVM-originated loopback TCP ("muse: Other TCP connections is turned off for
  this assistant"), which the Gradle daemon handshake requires. Verified with
  a minimal Java-vs-Python socket repro; proxy env, OOM, ports, registry, and
  heap size all ruled out. No evasion attempted (platform policy). **Unblock:**
  allow TCP for the assistant per the policy message ("ask the user to open
  Muse"), then re-run `flutter build apk --debug`; lower `org.gradle.jvmargs`
  from `-Xmx8G` for this 7.7GB VM first. Full evidence in QA_REPORT.md
  ("Overnight completion"). Unblocked by: platform/user action, then a single
  build command.
- **Production billing unverified.** Billing exists only as an interface
  concept; no Play billing-library integration, no test-track run, no
  verification service ([BILLING_VERIFICATION_SERVICE_CONFIG_IF_USED]).
  Free levels are independent of this. Unblocked by: owner Play setup + Stage 6.

## Resolved overnight (2026-10-18)

- **All 20 levels authored (was: L02, L05–L20 stubs).** Every level is real
  content, catalog-validated with no cycles, and solver-proven with the actual
  engines (248 + full-suite checks, exit 0). Chain progression is live:
  L01–L10 playable offline in order; L11–L20 neutrally locked on the
  entitlement cache.

## Major

- **Final art entirely missing.** All 12 character poses, town map + 20
  improvement layers, 40 object states, parts/tiles, UI icons, stickers,
  tutorial gestures, celebration effects, launcher/store artwork — every row in
  `docs/ASSET_LIST.md` is `missing — development placeholder`. Stage 3 uses
  programmatic `TileArt` (CustomPainter shapes + pattern markings) as
  development art; it is not final art. Unblocked by: Stage 5.
- **No audio.** Nothing recorded or generated; voice scripts not yet written.
  `AudioService` is a wired no-op facade (lifecycle hooks in place, never
  autoplays). Narrated release blocked until scripts exist, are cast
  consistently, and are reviewed (spec §12). Unblocked by: Stage 5.
- **No on-device testing.** No phone/tablet inspection, no TalkBack run, no
  performance measurements (fps, cold start, size); `PathProviderSaveStorage`
  and the lifecycle observer are wired but unverified on a real device.
  Unblocked by: Stage 7 (needs toolchain/device).
- **L20 finale multi-stage UI missing (new, overnight audit).** `LevelScreen`
  falls back to "Unsupported puzzle type" for `puzzleType: finale`. Unreachable
  today — no purchase flow can grant the pack entitlement, and billing is
  owner-blocked — but the Town Picnic Finale needs a real 3-stage screen
  (with per-stage checkpoints) before the pack content is genuinely complete.
  Unblocked by: Stage 4 UI work + Stage 6 billing.

## Minor

- **Urdu strings unreviewed.** All `ur` copy in level JSONs is draft; a fluent
  speaker must review wording and narration before localization is called final
  (spec §13). No Urdu font is bundled yet — the app relies on platform font
  fallback (spec §13 requires bundled offline fonts). Unblocked by: Stage 5.
- **Stage 3 showcase deviation — RESOLVED 2026-10-18 (QA audit).** Chain
  progression is now live: `AppState.isPlayableNow` uses
  `Level.isLevelAvailable` (L01 always; Ln needs L(n−1) + prerequisites;
  L11–L20 need the entitlement). All 20 levels are authored, so L01–L10 are
  playable offline in order and pack levels show the neutral locked state.
  The `/level` route also guards against direct-navigation bypass.
  (Supersedes the older showcase-deviation entry in DECISIONS.md.)
- **`com.example` application ID is temporary.** The real ID is the owner
  placeholder [FINAL_ANDROID_APPLICATION_ID]; must be set before any store
  work. Unblocked by: owner confirmation.
- **Web build is a dev artifact.** `flutter build web` succeeds, but per spec §1
  it establishes nothing about Android compatibility, performance, or billing.
  Never present it as an Android build.
- **Store materials absent.** No 512×512 icon, no 1024×500 feature graphic,
  no real screenshots, no listing drafts; palette contrast untested.
  Unblocked by: Stages 5–7.
- **Privacy policy + data inventory absent.** Must match the real implementation
  once it exists; placeholders [DEVELOPER_OR_BUSINESS_NAME],
  [SUPPORT_EMAIL], [PUBLIC_PRIVACY_POLICY_HTTPS_URL] still owner-controlled.
  Unblocked by: Stages 6–7.
- **No version control initialized.** Changes are files on disk only; spec §24
  calls for version control when available. Unblocked by: owner/tooling choice.
