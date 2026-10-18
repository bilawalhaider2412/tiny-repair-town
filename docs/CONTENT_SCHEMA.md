# Content Schema — Tiny Repair Town

Version: **1** (field `schemaVersion`, integer, required on every level file).
Status: Stage 1/2. This document is the contract for `assets/levels/*.json`, the Dart
engines in `lib/`, the content validator, and the web preview. Changes bump
`schemaVersion` and get a migration note in `core/save_data.dart`.

## Level file layout

```jsonc
{
  "id": "L01",                    // unique, L01..L20
  "schemaVersion": 1,
  "accessTier": "free",           // "free" | "pack"  (L01–L10 free, L11–L20 pack)
  "puzzleType": "matchParts",     // "matchParts" | "buildOrder" | "restorePattern" | "finale"
  "locationId": "workshop",       // workshop | toyCorner | bicycleStop | playground | sunnyPark
  "prerequisites": [],            // level ids that must be complete first; no cycles
  "title": {"en": "Wobbly Toy Car", "ur": "لڑکھڑاتی کھلونا گاڑی"},
  "request": {"en": "…", "ur": "…"},   // one-sentence character request
  "requester": "nori",            // mira | pip | nori
  "tutorial": true,               // show skippable demo on first entry
  "hints": [
    {"strength": 1, "en": "…", "ur": "…"},
    {"strength": 2, "en": "…", "ur": "…"},
    {"strength": 3, "en": "…", "ur": "…"}
  ],
  "rewardId": "sticker_little_wheel",
  "mapImprovementId": "map_workshop_car_fixed",
  "assets": {"objectIncomplete": "car_broken.png", "objectComplete": "car_fixed.png"},
  "narrationIds": {"instruction": "L01_instruction"},
  "a11y": {"en": "…", "ur": "…"},       // semantic description of the puzzle screen
  "config": { /* puzzleType-specific, see below */ },
  "stub": false                   // true for L02–L20 scaffolds in Stage 2 (not playable)
}
```

All positions are **proportional** (0.0–1.0 of the work-area box) so resizing never
breaks matching. Distances (e.g. snap radius) are proportional too.

## puzzleType = matchParts  (System A)

```jsonc
"config": {
  "slots": [
    {"id": "slot_wheel", "acceptsPartId": "part_wheel",
     "x": 0.28, "y": 0.68, "allowedOrientations": [0]}
  ],
  "pieces": [
    {"id": "part_wheel", "shape": "circle",
     "label": {"en": "Wheel", "ur": "پہیہ"},
     "initialOrientation": 0, "rotationAllowed": false, "isDistractor": false}
  ],
  "snapRadius": 0.07,          // proportional distance piece↔slot for a drop to count
  "tapToPlace": true
}
```

Rules (mirrored by `lib/puzzles/match_parts.dart`):
- A drop/tap counts when the piece center is within `snapRadius` of the slot center.
- Correctness = `partId` matches `acceptsPartId` **and** piece orientation ∈ `allowedOrientations`.
- Correct → snap animation; engine sets `inputLocked` until the UI clears it.
- Incorrect → piece returns to tray; no penalty.
- One piece fills at most one slot; filled slots reject new pieces.
- Rotation is 90° steps, only when `rotationAllowed` and after the rotate control
  has been demonstrated (`tutorial` covers it; L11 is the first level using it).
- Distractor pieces (`isDistractor: true`) match no slot.

## puzzleType = buildOrder  (System B)

```jsonc
"config": {
  "steps": [
    {"id": "step_base", "partId": "part_base",
     "label": {"en": "Base", "ur": "بنیاد"},
     "prerequisites": []},
    {"id": "step_body", "partId": "part_body",
     "label": {"en": "Body", "ur": "ڈھانچہ"},
     "prerequisites": ["step_base"]}
  ]
}
```

Rules (`lib/puzzles/build_order.dart`):
- `selectPart(partId)`: accepted iff it completes a step whose prerequisites are all done.
- Wrong selection → gentle visual hint, state unchanged (never a full reset).
- Completed steps stay visible; `currentSteps` exposes the highlighted next step(s).
- Multiple valid next steps allowed only when authored with empty/fulfilled prerequisites.
- Step advancement is deterministic.

## puzzleType = restorePattern  (System C)

```jsonc
"config": {
  "rows": 2, "cols": 2,
  "reference": "kite_reference.png",   // always-visible reference image
  "cells": [
    {"id": "cell_0_0", "row": 0, "col": 0,
     "solutionTileId": "tile_red_star", "alternativeTileIds": []}
  ],
  "tiles": [
    {"id": "tile_red_star",
     "label": {"en": "Red star", "ur": "سرخ ستارہ"},
     "shape": "star", "pattern": "stripes"}
  ]
}
```

Rules (`lib/puzzles/restore_pattern.dart`):
- `fillCell(cellId, tileId)`: correct if `tileId` equals `solutionTileId` or is in
  `alternativeTileIds`. Wrong tiles can be replaced freely, no penalty.
- `isComplete` only when **every** cell holds an accepted tile.
- Tiles carry shape/pattern markings in addition to color (never color-only).

## puzzleType = finale  (L20 only)

```jsonc
"config": {
  "stages": [
    {"stageId": "finale_a", "puzzleType": "matchParts", "config": { /* A-config */ },
     "title": {"en": "…", "ur": "…"}},
    {"stageId": "finale_b", "puzzleType": "buildOrder", "config": { /* B-config */ }},
    {"stageId": "finale_c", "puzzleType": "restorePattern", "config": { /* C-config */ }}
  ]
}
```

Each stage reuses its system's engine and rules. Progress is checkpointed per
stage in `SaveData.checkpoints["L20"] = {"completedStages": [...]}`.

## Validation rules (content validator + `Level.validate()`)

1. Exactly 20 unique ids L01..L20; tiers match the launch table (L01–L10 free).
2. `prerequisites` reference existing ids and contain no cycles.
3. Every referenced asset/narration/reward/mapImprovement id is non-empty.
4. matchParts: every `acceptsPartId` exists in `pieces`; at least one non-distractor
   piece; solvable (each slot has exactly one matching non-distractor piece).
5. buildOrder: step graph is acyclic and every step is reachable from step(s) with
   no prerequisites; ≥3 and ≤5 steps.
6. restorePattern: every cell's `solutionTileId` exists in `tiles`; 3–8 cells.
7. All `title`/`request`/`hints` entries have both `en` and `ur` strings.
8. No remote URLs anywhere (`assets/*` ids are local bundle references).
9. `hints` has exactly 3 entries with strengths 1,2,3.

## Save data (see `core/save_data.dart`)

```jsonc
{
  "saveSchemaVersion": 2,
  "language": "en",                       // "en" | "ur"
  "audio": {"music": true, "effects": true, "narration": true},
  "accessibility": {"reducedMotion": false, "extraGuidance": false, "largeText": false},
  "completedLevels": ["L01"],
  "stickers": ["sticker_little_wheel"],
  "currentLevelId": "L02",
  "checkpoints": {"L01": {"engine": "matchParts", "state": {}}},
  "contentVersion": 1,
  "entitlement": {"productId": "tiny_repair_town_full_unlock",
                  "granted": false, "verifiedAt": null, "method": "none"},
  "parentGate": {"pinSet": false}
}
```

- Writes are atomic (temp file + rename) with a `.bak` copy; corrupt primary +
  corrupt backup → fresh defaults with `recoveredFromCorrupt: true` (surfaced, never crash).
- Migrations: v1 → v2 adds `accessibility.extraGuidance` (default false).
- Level availability: L01 always; Ln (n>1) needs L(n−1) complete **and**, for L11–L20,
  `entitlement.granted == true`. Local `granted` is a cache only; production
  verification is server-side per spec §18 (blocked until owner setup).
