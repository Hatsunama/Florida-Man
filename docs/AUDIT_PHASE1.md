# AUDIT — Phase 1 Vertical Slice Excellence

**Date:** 2026-09-04 (America/New_York)  
**Commit:** `729f1fd`  
**Base:** Phase 0 `04d29f8` + `docs/PLAN_100X.md` Phase 1  
**Scope:** Hub + stages index 0–3 only (Hub, DaytonaHangover, BoardwalkChaos, GasStationLegends)

## Acceptance criteria

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Tutorial beat map exists and is once-through | **PASS** | `TutorialService` + `TutorialController`; sequence move → jump → attack → dodge telegraph → Cold One → Crab King. Forever 4s hub toast spam removed. |
| Slice enemies visually upgraded | **PASS** | Beach Crab belly plate; Crab King `TideCrown`; Hotdog Cart canopy/umbrella/mustard; Slushie layered blob+eyes+drip; Angry Tourist visor/camera/fanny pack. Parts only. |
| Fall stakes or soft checkpoint on slice stages | **PASS** | SafetyFloor omitted for stage index 1–3; Y &lt; −6 soft-respawns at `checkpointX` with toast. Stages ≥4 keep SafetyFloor. |
| No Phase 0 regressions (`./scripts/check_invariants.sh`) | **PASS** | All 8 greps green (lookAlong, SPAWN_X=18, ClickablePrompt, HasIFrames, CombatService, MobileControls, SoundId, OilSlow). |
| Stage 1–3 telegraphs/spacing tuned | **PASS** | Longer base tele on BeachCrab/SandFlea/CrabKing/Tourist/Slushie/HotDog; EnemyService ×1.2 (≤2) / ×1.08 (3); wider wave spawn gaps. |
| Camera framing MidGate + miniboss | **PASS** | `CombatEvent` kind `focus` → `CameraController.Focus` (≤0.4s) + shake. |
| HUD persona icon slots | **PASS** | Colored `Icon`/`Glyph` frames beside persona names (readable, not text-only). |
| Newspaper + draft snappy open + input lock | **PASS** | Tween scale/fade open; dim `Active=true`; `InputController.SetEnabled(false)` retained. |
| Act 1 Steve event-tied lines | **PASS** | `Story.ACT1_EVENTS` + `SteveEventLine`; Cold One + Boardwalk collar hint; talk prefers pending event lines. |
| Weapon keys 1–3 stubs disabled | **PASS** | Silent One/Two/Three branches removed from `InputController` (Phase 3 owns weapons). |

## Grades (post Phase 1)

| Area | Grade | Delta |
|------|:-----:|-------|
| Onboarding (60s) | B | Was D — once-through beat map |
| Slice enemy readability | B− | Was C — silhouette step-up, still Parts |
| Fall UX (slice) | B | Was C — soft checkpoint stakes |
| Camera juice | C+ | Was C — Focus cuts on gate/miniboss |
| HUD personas | B− | Was C — icon color slots |
| UI modal polish | B− | Was C — snap open + lock |
| Steve Act 1 | B | Was C — event-tied, not rotate-only |
| Phase 0 invariants | B | Unchanged / green |

## Added steps before Phase 2

1. **P1.1 Studio hallway test** — 5-person “I know what to do in 60s” ≥80% (acceptance needs human play; not runnable in this agent box).
2. **P1.2 Trailer capture** — lighting/VFX/audio still placeholder; Phase 2 mesh/VFX kit should replace Part crowns before marketing stills.
3. **P1.3 Tutorial edge cases** — if player skips jump in hub, bonfire tip still fires on jump; consider forcing hubBonfire tip after move+3s if never jumped.
4. **P1.4 Soft-fall juice** — optional brief vignette / dust on checkpoint respawn (client VFX).
5. **P1.5 Weapon UX** — keys 1–3 removed; HUD still shows weapon text — Phase 3 should either wire EquipWeapon cycle or hide weapon line until unlocks matter.
6. **P1.6 MidGate on stage 1–2** — MidGate only builds for index ≥3; Focus on MidGate is Gas Station+. Miniboss Focus covers Daytona Crab King.
7. **P1.7 EnemyFactory Part budget** — slice upgrades add Parts; profile low-end before Phase 2 mesh swap.

## Gate to Phase 2

Phase 2 (art pipeline) may start after: invariants green + slice scope freeze (hero cast = Beach Crab, Crab King, Hotdog Cart, Slushie, Angry Tourist, Slushie King) + optional Studio smoke of tutorial once-through.

## Files touched (high level)

- **New:** `src/server/TutorialService.lua`, `src/client/Controllers/TutorialController.lua`, `docs/AUDIT_PHASE1.md`
- **Server:** `GameService.lua`, `WorldBuilder.lua`, `EnemyFactory.lua`, `EnemyService.lua`
- **Client:** `init.client.lua`, `InputController.lua`, `MovementController.lua`, `CameraController.lua`, `HUD.lua`, `Newspaper.lua`, `ItemDraft.lua`
- **Shared:** `Remotes.lua`, `Enemies.lua`, `Story.lua`
