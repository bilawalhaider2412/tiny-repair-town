# Tiny Repair Town — Play Store release checklist

Status: **not started** — the game code is complete and verified; everything
below is owner-side or release-packaging work. Work top to bottom.

Proposed order (assistant-suggested 2026-10-17; **not yet affirmed by _a**):
finish game → build signed AAB → _a creates Play Console account → testing
tracks → production.

## 1. Owner account (your side)
- [ ] Create a Google Play Console account — one-time **$25**, you must do this
      yourself (no one can register or pay on your behalf).
- [ ] **New personal accounts:** Google requires a closed test with **12+
      testers for 14 days** before production access — line up testers early
      (family, friends).

## 2. App identity (owner decisions — currently placeholders)
- [ ] Final Android application ID: `[FINAL_ANDROID_APPLICATION_ID]`
      (currently the temporary `com.example` value — must change before release)
- [ ] Play product ID for the one-time unlock (levels 11–20): `[CONFIRMED_PLAY_PRODUCT_ID]`
- [ ] Price for the unlock: `[OWNER_APPROVED_PRICE]`
- [ ] Developer name, support email, privacy-policy URL.

## 3. Signed release build (assistant side, once unblocked)
- [ ] Build the **signed AAB** (`flutter build appbundle --release`) with your
      keystore. Keystore creation/storage is an owner decision — debug builds
      so far use only the auto debug key; **no release keystore exists yet**.
- [ ] Requires the APK/AAB toolchain path to be open (see
      `docs/BUILD_APK_ON_YOUR_PC.md` and `.github/workflows/build-apk.yml`).

## 4. Store listing assets (assistant side)
- [ ] 512×512 store icon, feature graphic.
- [ ] Real screenshots from the game.
- [ ] Listing text in English **and** Urdu.
- [ ] Privacy policy draft (from the real implementation, not guesses).

## 5. Play Console declarations
- [ ] Target audience: children **6–8** → triggers **Families policy**:
      no ads, one-time purchase behind a **parent gate**, no manipulative
      purchase prompts.
- [ ] In-app product: one-time purchase for levels 11–20 (billing is currently
      interface-only — real Play Billing integration still to do).
- [ ] Data safety form: describe what the app actually collects (the game is
      offline-first with local saves; fill from the real implementation).

## 6. Testing tracks → production
- [ ] Upload AAB to the **internal testing** track first.
- [ ] Promote to **closed testing** with 12+ testers for 14 days (new-account rule).
- [ ] Pass Google's Families-policy review.
- [ ] Promote to production.

## Known honest limits before release
Final art/audio are placeholders; Urdu not fluent-reviewed; no physical-device
testing yet. See `docs/QA_REPORT.md` and `docs/KNOWN_ISSUES.md`.
