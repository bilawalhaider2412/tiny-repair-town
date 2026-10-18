# Building the Tiny Repair Town APK on your own computer

**What this is:** the fallback path for producing an installable APK while the
dev VM's sandbox blocks Gradle's local-network connections. On your own PC the
build is one command — the project is complete and verified (20 real levels,
14 bugs fixed overnight, all tests green).

**What you get:** a debug APK that installs and plays on any Android phone for
testing. The store-ready signed release (AAB) comes later — see
`docs/RELEASE_CHECKLIST.md`.

**Time needed:** ~30–60 minutes of downloads (one time), then one build of
~10–25 minutes the first time.

---

## Option A — Windows (most common)

### 1. Install Flutter
1. Download the Flutter SDK (stable, Windows) from https://docs.flutter.dev/get-started/install/windows
2. Extract it, e.g. to `C:\src\flutter` (avoid paths with spaces).
3. Add `C:\src\flutter\bin` to your PATH (search "environment variables" → edit Path).
4. Open a new terminal and run: `flutter doctor`

### 2. Install the Android SDK (command-line tools only — no full Android Studio needed)
1. Download "Command line tools only" for Windows from https://developer.android.com/studio#command-line-tools-only and unzip to a folder, e.g. `C:\Android\cmdline-tools\latest` (the zip contains a `cmdline-tools` folder — move its *contents* into `latest`).
2. Set environment variables (same "environment variables" screen):
   - `ANDROID_HOME` = `C:\Android`
   - `ANDROID_SDK_ROOT` = `C:\Android`
   - Add `C:\Android\cmdline-tools\latest\bin` and `C:\Android\platform-tools` to PATH.
3. In a new terminal, install the packages and accept licenses:
   ```
   sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
   sdkmanager --licenses
   ```
   (Answer `y` to each license.)
4. Install a JDK 17 if you don't have one (Temurin 17 from https://adoptium.net works) and set `JAVA_HOME` to it.

### 3. Build
1. Copy the `tiny-repair-town` project folder to your PC (the zip of it is the
   easiest — it contains everything including the pure-Dart package the app
   depends on via `path: ../`; keep the folder structure intact).
2. In a terminal:
   ```
   cd tiny-repair-town\app
   flutter pub get
   flutter build apk --debug
   ```
3. The APK lands at:
   `tiny-repair-town\app\build\app\outputs\flutter-apk\app-debug.apk`

### 4. Install on your phone
1. Copy `app-debug.apk` to the phone (USB, Google Drive, WhatsApp to yourself…).
2. Open it on the phone and allow "Install unknown apps" when Android asks.
3. Play. Saves, hints, Urdu/English toggle, and all 20 levels work offline.

## Option B — macOS / Linux

Same idea: install Flutter per https://docs.flutter.dev/get-started/install,
install the Android cmdline-tools + the three packages above, set
`ANDROID_HOME`/`ANDROID_SDK_ROOT`/`JAVA_HOME`, then run the two commands from
`tiny-repair-town/app/`.

## Troubleshooting
- `flutter doctor` shows exactly what's missing — fix items top to bottom.
- First build downloads Gradle + dependencies (~1 GB); a slow or interrupted
  download just needs a re-run.
- "SDK location not found": `ANDROID_HOME`/`ANDROID_SDK_ROOT` isn't set or the
  terminal was opened before you set it — open a fresh terminal.

## Honest limits of this APK (unchanged)
Placeholder art/audio, Urdu not fluent-reviewed, billing interface-only
(levels 11–20 unlock is stubbed, not real Play billing), temporary
`com.example` application ID, never tested on a physical device yet.
