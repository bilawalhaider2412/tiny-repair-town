# Asset List — Tiny Repair Town

Status: 2026-10-18 (Stage 2). Per spec §11. **Every row is currently
`missing — development placeholder`.** Nothing below has been illustrated,
recorded, or licensed. The dev web preview of L01 uses programmatic SVG/CSS
art only; that is *not* final art and must not ship.

Filenames shown are the *planned* conventions, grounded where a level file
already references them (e.g. `car_broken.png` in L01). "Source" and "License"
columns record provenance once real assets are commissioned; do not fill them
with invented values.

## 1. Characters (3 × 4 poses = 12)

Characters: **Mira** (warm repair guide, colorful overalls), **Pip** (small
rounded helper robot, expressive eyes), **Nori** (cheerful rabbit, brings toys).
Style: rounded shapes, warm palette (cream #FFF5E6, blue #63B8E8, green
#7BCB8B, coral #F28C7A, yellow #F5CF63, text #243746 — contrast untested,
not accessibility-approved).

| Filename | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `mira_idle.png` | Mira standing pose | 512×512 | TBD (commission) | TBD | missing — development placeholder |
| `mira_explain.png` | Mira gesture-explaining pose | 512×512 | TBD | TBD | missing — development placeholder |
| `mira_encourage.png` | Mira encouraging pose | 512×512 | TBD | TBD | missing — development placeholder |
| `mira_celebrate.png` | Mira celebrating pose | 512×512 | TBD | TBD | missing — development placeholder |
| `pip_idle.png` | Pip idle | 512×512 | TBD | TBD | missing — development placeholder |
| `pip_explain.png` | Pip explaining | 512×512 | TBD | TBD | missing — development placeholder |
| `pip_encourage.png` | Pip encouraging | 512×512 | TBD | TBD | missing — development placeholder |
| `pip_celebrate.png` | Pip celebrating | 512×512 | TBD | TBD | missing — development placeholder |
| `nori_idle.png` | Nori idle | 512×512 | TBD | TBD | missing — development placeholder |
| `nori_explain.png` | Nori explaining | 512×512 | TBD | TBD | missing — development placeholder |
| `nori_encourage.png` | Nori encouraging | 512×512 | TBD | TBD | missing — development placeholder |
| `nori_celebrate.png` | Nori celebrating | 512×512 | TBD | TBD | missing — development placeholder |

## 2. Town map + improvement layers (21)

One base map of the five locations (Workshop, Toy Corner, Bicycle Stop,
Playground, Sunny Park); one improvement layer per level, revealed on
completion (e.g. `map_workshop_car_fixed`).

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `town_map_base.png` | Full town map, base state | 2048×2048 | TBD | TBD | missing — development placeholder |
| `map_workshop_car_fixed.png` | L01 improvement (named in level file) | 2048×2048 | TBD | TBD | missing — development placeholder |
| `map_{location}_{level}_*.png` (×19 more) | One improvement layer per remaining level | 2048×2048 | TBD | TBD | missing — development placeholder |

## 3. Repair objects, broken/fixed (40)

One incomplete + one complete state per level (20 levels). Example grounded in
L01: `car_broken.png` / `car_fixed.png`.

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `<object>_broken.png` (×20, e.g. `car_broken.png`) | Object incomplete state | 1024×1024 | TBD | TBD | missing — development placeholder |
| `<object>_fixed.png` (×20, e.g. `car_fixed.png`) | Object repaired state | 1024×1024 | TBD | TBD | missing — development placeholder |

## 4. Puzzle parts and trays

Part/piece art per level config (slots, pieces, steps, tiles). Tray
backgrounds shared across levels.

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `part_<id>.png` (per piece in each level config) | Draggable/tappable puzzle piece | 512×512 | TBD | TBD | missing — development placeholder |
| `slot_<id>.png` (per slot) | Target outline / drop zone art | 512×512 | TBD | TBD | missing — development placeholder |
| `tile_<id>.png` (pattern tiles) | Restore-pattern tiles | 512×512 | TBD | TBD | missing — development placeholder |
| `tray.png` | Shared piece-tray background | 1024×512 | TBD | TBD | missing — development placeholder |
| `pattern_reference_<id>.png` (e.g. `kite_reference.png`) | Always-visible pattern references | 1024×1024 | TBD | TBD | missing — development placeholder |

## 5. UI buttons and icons

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `btn_play.png`, `btn_back.png`, `btn_home.png`, `btn_hint.png`, `btn_pause.png`, `btn_replay_audio.png` | Core buttons | 256×256 (min touch target ≥56dp enforced in layout) | TBD | TBD | missing — development placeholder |
| `icon_parents.png`, `icon_settings.png`, `icon_language.png`, `icon_sound_*.png` | Nav/settings icons | 192×192 | TBD | TBD | missing — development placeholder |
| `icon_lock_neutral.png` | Neutral "More activities in Parents" lock (no price/pressure) | 192×192 | TBD | TBD | missing — development placeholder |

## 6. Sticker book + 20 stickers

Deterministic rewards, one per level, awarded once on first completion.

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `sticker_book.png` | Sticker book background/pages | 2048×1536 | TBD | TBD | missing — development placeholder |
| `sticker_<id>.png` (×20, e.g. `sticker_little_wheel.png`) | Earned stickers | 512×512 | TBD | TBD | missing — development placeholder |

## 7. Tutorial gestures

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `gesture_drag.png` | Animated drag demonstration | 512×512 (animated) | TBD | TBD | missing — development placeholder |
| `gesture_tap.png` | Animated tap-place demonstration | 512×512 (animated) | TBD | TBD | missing — development placeholder |
| `gesture_rotate.png` | Rotate-control demo (first used L11) | 512×512 (animated) | TBD | TBD | missing — development placeholder |

## 8. Celebration effects

| Filename pattern | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `fx_confetti.png` | Celebration particles (reduced-motion safe alternative required) | 256×256 sprite sheet | TBD | TBD | missing — development placeholder |
| `fx_sticker_reveal.png` | Sticker award reveal | 512×512 | TBD | TBD | missing — development placeholder |
| `fx_map_reveal.png` | Town improvement reveal | 1024×1024 | TBD | TBD | missing — development placeholder |

## 9. Launcher and store artwork

| Filename | Purpose | Dimensions | Source | License | Review status |
|---|---|---|---|---|---|
| `ic_launcher` (adaptive, fg/bg) | Android adaptive launcher icon | 108×108dp (432×432 px @xxxhdpi, both layers) | TBD | TBD | missing — development placeholder |
| `store_icon.png` | Play Store icon | 512×512 PNG | TBD | TBD | missing — development placeholder |
| `feature_graphic.png` | Play Store feature graphic | 1024×500 (current format reqs to recheck, spec §20) | TBD | TBD | missing — development placeholder |

## 10. Voice/narration scripts — NOT RECORDED

No audio has been recorded or generated. The voice script table is **pending
Stage 5**. Required columns per line: line ID, English text, Urdu text,
character (Mira/Pip/Nori), delivery direction, runtime filename (e.g.
`narration/L01_instruction_en.mp3`). Until scripts are written, cast-reviewed,
recorded and reviewed, the narrated release is blocked (spec §12). Do not
reference narration files that do not exist; level `narrationIds` (e.g.
`L01_instruction`) are content keys, not proof of audio.
