# AUDIT — Phase N1 GameService Split

**Date:** 2026-09-04 (America/New_York)  
**Base:** `c033565` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N1  
**Prior:** [`AUDIT_N0.md`](AUDIT_N0.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| `wc -l GameService.lua` ≤ 400 | **PASS** | 259 lines |
| No behavior change on smoke 1–3 | **PASS*** | Extract-only + N0.1/N0.2/N0.4; Studio smoke not run (agent rule) |
| Meta/Hazard remain sole owners | **PASS** | Persist still MetaService; hazards still HazardService.Tick from pump |
| `./scripts/check_invariants.sh` green | **PASS** | Prior N0 + N1 service/line-budget checks |
| Dialogue popup-only | **PASS** | No new VO/SFX dialogue paths; Tagline/Toast/Newspaper unchanged |

\*Agent did not open Studio; smoke paths preserved by moving code without logic rewrite except documented N0 follow-ups.

## Extract map

| Module | Lines | Owns |
|--------|------:|------|
| `GameService.lua` | 259 | InitPlayer, require/wire remotes, tick pump, GetState/ApplyDamage facade |
| `RunContext.lua` | 327 | states table, PushState/Toast/ComputeStats/NewRunState/speed/look, TryGrantItem |
| `DraftService.lua` | 108 | newspaper continue, daily-luck draft roll, PickDraftItem, skip-draft if full |
| `HubService.lua` | 172 | StartRun, Steve talk, Smash/Upgrade persona |
| `StageFlowService.lua` | 495 | LoadHub/LoadStage, TickWaves, MidGate, Cold One, FinishStage/FinishRun, kill/rescue callbacks |
| `CombatFacade.lua` | 464 | DoAttack/Skill/Dodge/Swap, ApplyDamage/KillPlayer, EquipWeapon, GrantEnemyDrop |

Wiring uses `Init(deps)` bags so modules do not circular-require each other at load time.

## N0 follow-ups addressed

| # | Item | Result |
|---|------|:------:|
| N0.1 | Enemy drop hard `itemSlots` (remove `math.max(..., 8)`) | **PASS** — `CombatFacade.GrantEnemyDrop` → `RunContext.TryGrantItem` |
| N0.2 | Skip draft UI when slots full | **PASS** — `DraftService.beginDraftOrSkip` auto-advances |
| N0.3 | Types adoption | **PASS** — `Types.RunState` (+ tutorial/steve fields); `MetaService.MetaProfile = Types.MetaProfile`; GameService/RunContext re-export |
| N0.4 | Mobile ATK localSwing | **PASS** — `InputController.TryAttack`; MobileControls ATK calls it |
| N0.5 | Live Studio RequestJump RemoteEvent | **DEFER** — still needs one-time Studio Remotes cleanup (no Studio this pass) |

## Invariants script (N1)

```
OK  … (all N0 checks)
OK  PickDraftItem itemSlots
OK  DraftService / HubService / StageFlowService / CombatFacade modules
OK  CombatFacade CombatService
OK  N0.1 hard itemSlots grant
OK  N0.2 skip-draft full
OK  N0.4 mobile TryAttack
OK  GameService <=400 (259)
```

## Dialogue policy (unchanged)

Conversations = Tagline / Toast / Newspaper only. Combat SFX retained.

## Added steps before N2

1. **N1.1 Studio smoke** — hub → stages 1–3: StartRun, Cold One walkover, MidGate lock/clear, newspaper → draft → next stage; confirm skip-draft when slots full.  
2. **N1.2 PendingDamage** — N2 task: replace attr PendingDamage with EnemyService.OnPlayerHit callback owned by CombatFacade.  
3. **N1.3 CombatFacade size** — still ~464 lines; N6 can move moveset/docs without growing GameService.  
4. **N1.4 RunContext vs Types** — server runtime fields (`tutorial`, steve events) now on shared Types; keep single source of truth (avoid re-diverging GameService-local export).  
5. **N1.5 Remotes folder (N0.5)** — document Studio one-shot delete of stale `RequestJump` instances on long-lived places.  
6. **N1.6 Double InitServer** — `init.server.lua` and `GameService.SetupRemotes` both call `Remotes.InitServer()` (pre-existing); optional tidy to single call in N2.

## Gate to N2

N2 (trust & edge hardening) may start: GameService ≤400, services extracted, invariants green, dialogue policy intact. Prefer N1.1 Studio smoke before PendingDamage callback cutover.
