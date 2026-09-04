# AUDIT — Phase 4 World & Story Production

**Date:** 2026-09-04 (America/New_York)  
**Commit:** `2af587e`  
**Base HEAD before work:** `1b23dcf`  
**Scope:** Set-piece gameplay verbs per act, MidGate room system, Spillfather slick rings, story staging (newspaper panels + Steve vignettes + turtle Focus), SafetyFloor removal / global soft-fall, biome ambient particles. Soft Act3 branch skipped (rescue-first gate kept). No Studio.

## Acceptance checklist

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Each act ≥1 gameplay set-piece (not décor) | **PASS** | See set-piece matrix below |
| Spillfather phases change positioning | **PASS** | Phase 2 expands slick ring; phase 3 contracts + thickens (`EnemyService.UpdateSpillfatherSlickRing`) |
| Story beat readable via newspaper/Steve on act change | **PASS** | `Story.NewspaperPanels` + Newspaper Frames; `lastActShown` Steve vignette on act cross |
| Invariants 8/8 | **PASS** | `./scripts/check_invariants.sh` all OK |
| Added steps before Phase 5 | **PASS** | See below |
| No Studio / rbxlx open | **PASS** | Agent did not launch Studio |

## Must-ship tasks

| # | Task | Result | Notes |
|---|------|:------:|-------|
| 1 | Act set-piece verbs | **PASS** | Act1 fryer timed HOT windows + ledges; Act2 canal water slow + pad chain; Act3 turtle `ProximityPrompt` Rescue; Act4 conveyor/pipeSpray damage+displace; Act5 barge gaps + checkpoint pads + soft-fall |
| 2 | MidGate → room system | **PASS** | `MidRoomZone` enter → barrier lock + wave + `arenaLock` camera; clear → fanfare toast + `arenaUnlock` Focus |
| 3 | Spillfather slick ring phases | **PASS** | `SpillfatherSlickRing` segs; phase 2/3 resize/recolor damage ring (safe pocket changes) |
| 4 | Story staging | **PASS** | Newspaper act art panels; Steve vignette on act change; turtle rescue Focus + quota tagline |
| 5 | SafetyFloor → soft checkpoint | **PASS** | SafetyFloor removed globally; soft-fall + checkpoint advance for all `stageIndex >= 1`; barge `Checkpoint` pads |
| 6 | Ambient particles per biome | **PASS** | `WorldBuilder._Ambient` — bugs swamp, sparks facility, spray beach/offshore, neon dust town |
| 7 | Soft branch Act3 optional | **SKIPPED** | Rescue-first gate already (`FinishStage` blocks until turtle quota). Choice toast not added — document as prefer-existing |

## Set-piece matrix (gameplay, not décor)

| Act | Stage / setPiece | Verb |
|-----|------------------|------|
| 1 | Boardwalk `fryerOil` + Gas `neonCanopy` fryer | Timed `HazardPeriod`/`Duty` — standing in HOT window damages; jump ledges / wait cool |
| 2 | Canal `canalPads` | Deep water `WaterSlow` (moveSpeed≤7); Neon pad chain `PadBoost` required for pace |
| 3 | Turtle nests + `RescueTurtle` | Dedicated `ProximityPrompt` (`FM_Action=RescueTurtle`); attack-near kept as fallback; Focus cinematic |
| 4 | Lab `labConveyor` / Pipe `pipeMaze` | `conveyor` push+damage; moving `Sample` Parts; `pipeSpray` timed burst + `DisplaceY` |
| 5 | Barge `bargeGaps` + offshore gaps | Real deck gaps; CKPT pads; soft-fall respawn (no SafetyFloor) |

## MidGate room flow

1. Stages `index >= 3` build `MidGate` (locked) + `MidRoomZone` + `MidRoomBarrier`.
2. Player enters zone → `midRoomState=locked`, barrier collides, arena camera lock, pocket wave spawn.
3. `CountHostile()==0` → unlock gate, barrier off, fanfare toast + `SFX_DraftSting` + Focus.

## Spillfather positioning

| Phase | Ring | Player strategy |
|-------|------|-----------------|
| 1 | Hidden (Transparency 0.85) | Open arena |
| 2 | Radius 16, dmg 6 | Stay in center safe pocket; ring expands walkable-risk zone |
| 3 | Radius 9, thicker, dmg 9 | Ring contracts — reposition to outer nest pads / outside hot band |

## Story staging

- `Story.NEWSPAPER_PANELS[1..5]` → colored Frames on `Newspaper.Show`
- Act cross: `Story.ActOpener` toast + Steve `ShowTagline` (deduped vs per-stage Steve)
- Turtle quota complete: Steve tagline + Focus on rescue

## Soft branch (Act3) — skipped

Rescue-first gating already blocks `FinishStage` until `turtlesRescued >= turtlesNeeded`. A toast choice ("rescue first" vs "push gate") was **not** added to avoid heavy UX; prefer existing gate. Optional Phase 5 polish if designers want an explicit soft-branch prompt.

## Invariants (Phase 0 lock)

```
OK  lookAlong facing
OK  SPAWN_X = 18
OK  ClickablePrompt
OK  HasIFrames server
OK  CombatService require GS
OK  MobileControls
OK  SoundId smoke
OK  OilSlow
```

## Grades (post Phase 4)

| Area | Grade | Delta |
|------|:-----:|-------|
| World set-pieces | **B** | Was C — verbs damage/slow/displace, not décor-only |
| MidGate / rooms | **B** | Was C+ — enter/lock/wave/clear/fanfare |
| Boss arena phases | **B** | Was B− — geometry-ish slick ring alters footing |
| Story staging | **B** | Was C — panels + act Steve vignettes |
| Fall UX (global) | **B** | Was B slice-only — SafetyFloor gone, soft CKPT all stages |
| Biome ambience | **B−** | Was D — light particles present |
| Act3 branch | **C+** | Soft choice skipped; rescue gate honest |

## Added steps before Phase 5

1. **P4.1 Studio smoke** — Boardwalk fryer HOT windows; Canal pad chain; turtle Press E; Lab conveyor hit; Barge fall → soft CKPT; MidGate room lock/clear; Spillfather phase 2/3 ring visible.
2. **P4.2 MidGate tuning** — wave composition per biome table; prevent double-trigger if player re-enters zone; barrier feel on mobile.
3. **P4.3 Slick ring polish** — animate radius tween; safe-zone decal; toast only once per phase per player (FireAllClients → targeted).
4. **P4.4 Newspaper art** — replace flat color Frames with Phase 2 icon pack / SurfaceAppearance panels when ready.
5. **P4.5 Ambient audio beds** — pair biome particles with looping ambience (Phase 5 audio director).
6. **P4.6 Optional Act3 choice toast** — only if design wants soft branch beyond rescue-first gate.
7. **P5 gate:** campaign polish + audio may start; do not expand stage count until Studio confirms set-piece verbs read.

## Gate to Phase 5

Phase 5 (full campaign polish + audio) may start. Prefer P4.1 Studio confirmation before trailer cuts of Acts 2–5.

## Files touched

- **New:** `docs/AUDIT_PHASE4.md`
- **Server:** `WorldBuilder.lua`, `GameService.lua`, `EnemyService.lua`, `EnemyFactory.lua`
- **Shared:** `Story.lua`
- **Client:** `Newspaper.lua`, `CameraController.lua`, `init.client.lua`
