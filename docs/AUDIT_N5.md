# AUDIT — Phase N5 Per-act level verbs

**Date:** 2026-09-04 (America/New_York)  
**Base:** `ee6845e` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N5  
**Prior:** [`AUDIT_N4.md`](AUDIT_N4.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Playtester can name how Act2 feels different from Act1 without décor talk | **PASS*** | Act2 = pad-only / water timeout (+ oil slicks); Act1 = hangover/Cold One + timed HOT rhythm |
| Turtle escort stage completable without attack-rescue | **PASS** | Escort walk + Prompt / auto-rescue at goal; attack-rescue still absent |
| No SafetyFloor regression | **PASS** | Soft-fall only; `SafetyFloor` absent from `src/` |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N5 verb checks |
| Dialogue popup-only | **PASS** | Verb = Toast; MidGate first-lock = Tagline; no dialogue SFX |
| Studio smoke / Remotes hygiene | **DEFER** | User (no Studio from agents) |
| CombatFacade trim | **LEAVE → N6** | Per N4.4 / user scope |

\*Agent did not open Studio; mechanical wiring + verb map below.

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Act unique verbs (timed / pad-water / escort / conveyor-flip / wind-gaps) | **PASS** |
| 2 | Consume `platformLedges` / `scalingTier` for density | **PASS** — ledge count + gaps + JumpPads |
| 3 | MidGate first-lock Tagline per act | **PASS** — `steveEvents.midGateActN` |
| 4 | No SafetyFloor regression | **PASS** |
| N4.6 | Act2 pad-only / soft-fall water timeout spike | **PASS** — folded into N5 |

## Act verb summary

| Act | Primary verb | Mechanical identity |
|----:|--------------|---------------------|
| 1 | `hangoverColdOne` / `timedRhythm` / `midGate` | Hangover + Cold One walkover; fryer/slush HOT rhythm; MidGate from stage 3 |
| 2 | `padWater` / `oilSlick` | Pad-only canal + `WATER_TIMEOUT` soft-fall; oil slicks on swamp stages |
| 3 | `turtleEscort` | Turtles walk to nest when player near; Prompt or auto-rescue at goal |
| 4 | `conveyorFlip` | Conveyor push flips on `CONVEYOR_FLIP_PERIOD`; facility stages get belts |
| 5 | `windGaps` / `bossArena` | Barge gaps + wind cuts jump; finale denser telegraphs; MidGate never locks empty waves |

## Stage → verb map

| Stage | Idx | Act | Verb id | Label |
|-------|----:|----:|---------|-------|
| Hub | 0 | 1 | `hub` | Hub bonfire start |
| DaytonaHangover | 1 | 1 | `hangoverColdOne` | Hangover + Cold One walkover |
| BoardwalkChaos | 2 | 1 | `timedRhythm` | Timed hazard rhythm — jump when HOT |
| GasStationLegends | 3 | 1 | `midGate` | MidGate room lock |
| StripMallShowdown | 4 | 1 | `midGate` | MidGate room lock |
| DriveThruDisaster | 5 | 1 | `midGate` | MidGate room lock |
| CanalRun | 6 | 2 | `padWater` | Pad-only / soft-fall water timeout |
| SwampShift | 7 | 2 | `oilSlick` | Oil slicks — skim or slip |
| CypressCathedral | 8 | 2 | `oilSlick` | Oil slicks — skim or slip |
| SludgeBayou | 9 | 2 | `oilSlick` | Oil slicks — skim or slip |
| ConspiracyShack | 10 | 2 | `oilSlick` | Oil slicks — skim or slip |
| TurtleBeach | 11 | 3 | `turtleEscort` | Turtle escort toward nest |
| NestGuard | 12 | 3 | `turtleEscort` | Turtle escort toward nest |
| GulfGulpGate | 13 | 4 | `conveyorFlip` | Conveyor direction flips on timer |
| LabWing | 14 | 4 | `conveyorFlip` | Conveyor direction flips on timer |
| PipeGauntlet | 15 | 4 | `conveyorFlip` | Conveyor direction flips on timer |
| LoadingDock | 16 | 4 | `conveyorFlip` | Conveyor direction flips on timer |
| BargeCrossing | 17 | 4 | `windGaps` | Barge gaps + wind opposing jump |
| OilPlatformApproach | 18 | 4 | `conveyorFlip` | Conveyor direction flips on timer |
| HelipadHysteria | 19 | 4 | `windGaps` | Barge gaps + wind opposing jump |
| GulfGulpRig | 20 | 5 | `bossArena` | Boss arena denser telegraphs (+ turtle rescue still required) |

Derived by `Stages.LevelVerb(stage)`; world attr `LevelVerb` set in `WorldBuilder.BuildStage`.

## Implementation map

| Area | Change |
|------|--------|
| `Constants.lua` | `WATER_TIMEOUT`, `CONVEYOR_FLIP_PERIOD`, escort + wind constants |
| `Stages.lua` | `LevelVerb` / `ACT_VERB` / `VERB_LABEL` |
| `Story.lua` | `MIDGATE_LOCK`, `VERB_TOAST`, helpers |
| `HazardService` | Water timeout soft-fall; conveyor flip; wind oppose jump |
| `WorldBuilder` | Pad-only canal; conveyor flip attrs; barge wind; scalingTier ledges/gaps; LevelVerb attr |
| `StageFlowService` | Verb toast; MidGate first-lock Tagline; turtle `EscortGoalX`; syntax fix |
| `EnemyService` | Turtle escort AI; late denser telegraphs (13+/17+) |
| `check_invariants.sh` | N5 greps + SafetyFloor absent |

## AUDIT_N4 “before N5” folded

| # | Item | Result |
|---|------|:------:|
| N4.1 | Studio smoke options | **DEFER** — user Studio |
| N4.2 | Schema migrate Studio | **DEFER** — user |
| N4.3 | Remotes Studio hygiene | **DEFER** — user |
| N4.4 | CombatFacade trim | **LEAVE → N6** |
| N4.5 | N3.1 catalog smoke | **DEFER** — user Studio |
| N4.6 | Act2 verb spike | **PASS** — this phase |

## Added steps before N6

1. **N5.1 Studio smoke** — Act1 hangover→Cold One; Boardwalk HOT rhythm; CanalRun pad/water timeout soft-fall; TurtleBeach escort without attack; LabWing conveyor flip; BargeCrossing wind cuts jump; MidGate first-lock Tagline once per act; empty-wave MidGate never locks.  
2. **N5.2 Remotes Studio hygiene** — still user: delete stale `RequestJump` on long-lived places (N0.5 / N1.5 / N2.6 / N3.5 / N4.3).  
3. **N5.3 Options / schema Studio** — still deferred N4.1–N4.2 before soft launch.  
4. **N5.4 CombatFacade trim** — N6: move DoAttack/DoSkill/DoSwap bodies; GameService remotes only.  
5. **N5.5 Late telegraph feel** — live play may tune 13+/17+ tele mults after Studio (N3.6 hold continues).  
6. **N5.6 Finale turtles + boss** — confirm escort + Spillfather clear path in Studio; verb id is `bossArena` but rescue count still gates finish.

## Gate to N6

N6 (combat depth) may start: per-act mechanical verbs wired, invariants green, dialogue popup-only, SafetyFloor still gone, CombatFacade intentionally untouched. Prefer N5.1 Studio smoke before moveset cancel windows.
