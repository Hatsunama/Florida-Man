# AUDIT — Phase N6 Combat facade depth

**Date:** 2026-09-04 (America/New_York)  
**Base:** `640af63` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N6  
**Prior:** [`AUDIT_N5.md`](AUDIT_N5.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Lawn Dart arc vs Roman Candle flat distinct | **PASS*** | Thrown uses `THROW_ARC_HEIGHT` (+dart boost); ranged stays flat/fast |
| No client-only god swings during server recovery | **PASS** | `attackReadyAt` via StateUpdate + CombatEvent; `InputController.SyncAttackReady` |
| CombatFacade trim ≤ ~250–300 lines | **PASS** | **123** lines (was 468) |
| Hitstop / flinch / swap juice intact | **PASS** | EnemyService hitConnect + FlinchUntil; swap VFX/hitstop; punish flash |
| Pierce caps (N3) preserved | **PASS** | `RANGED_PIERCE_HITS` / `pierceLeft` unchanged |
| Ember / GREASY still fire | **PASS** | Ember on dodge in `SwapService`; on-hit mult in `AttackService`; GREASY oilResist untouched |
| Token buckets / server authority intact | **PASS** | `takeToken` in GameService remotes; HasIFrames server-table |
| No fake Mesh IDs | **PASS** | No new asset IDs |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N6 checks |
| Dialogue popup-only | **PASS** | Swap punish = Toast (+ red tint); cancel = HUD flash; no VO |
| Studio smoke / Remotes hygiene | **DEFER** | User (no Studio from agents) |

\*Agent did not open Studio; projectile arc vs flat wiring verified in code.

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Extract DoAttack / DoSkill / DoSwap (+ dodge) into focused modules; GameService remotes only | **PASS** |
| 2 | Moveset cancel windows in Types + HUD flash | **PASS** — `cancelAfter` + `FlashCancel` |
| 3 | Weapon secondaries (foam vs fire, net roots) | **PASS** |
| 4 | Swap punish readable (color + Tagline-free Toast) | **PASS** — red Toast + `FlashPunish` |
| 5 | Client recovery reads server `attackReadyAt` | **PASS** |
| N5.4 | CombatFacade trim carryover | **PASS** |

## Line counts

| Module | Lines | Role |
|--------|------:|------|
| `CombatFacade.lua` | **123** | Init, damage/kill, equip, thin Do* delegates |
| `AttackService.lua` | 207 | DoAttack, on-hit specials, weapon secondaries |
| `SkillService.lua` | 138 | DoSkill kinds |
| `SwapService.lua` | 110 | DoDodge (ember) + DoSwap (punish) |
| `CombatService.lua` | 448 | Movesets/cancel, iframes, projectiles, pierce |
| `GameService.lua` | 304 | Remotes + token buckets only for combat |

## Implementation map

| Area | Change |
|------|--------|
| `AttackService` | Extracted attack + HitEnemy; foam fire mult; net `RootedUntil` |
| `SkillService` | Extracted skill bodies |
| `SwapService` | Extracted dodge/swap; ember buff; punish Toast |
| `CombatFacade` | Thin orchestrator; OnPlayerHit + ApplyDamage/Kill/Equip |
| `CombatService` | `cancelAfter` on movesets; `GetAttackReadyAt` / `InCancelWindow`; dart arc height |
| `Types.lua` | `MovesetHit` with `cancelAfter` |
| `Constants.lua` | `FOAM_FIRE_MULT`, `NET_ROOT_DURATION`, `THROW_ARC_HEIGHT`, `CANCEL_WINDOW_FLASH` |
| `RunContext` | StateUpdate pushes `attackReadyAt` / `cancelOpenAt` |
| `EnemyService` | `RootedUntil` movement gate (with flinch) |
| `InputController` | `SyncAttackReady` from server clock |
| `HUD` | `FlashCancel`, `FlashPunish`, punish Toast color |
| `init.client` | Wire cancel/punish/recovery sync |
| `check_invariants.sh` | N6 greps + CombatFacade ≤300 |

## AUDIT_N5 “before N6” folded

| # | Item | Result |
|---|------|:------:|
| N5.1 | Studio smoke level verbs | **DEFER** — user Studio |
| N5.2 | Remotes Studio hygiene | **DEFER** — user |
| N5.3 | Options / schema Studio | **DEFER** — user |
| N5.4 | CombatFacade trim | **PASS** — this phase |
| N5.5 | Late telegraph feel | **HOLD** — live play |
| N5.6 | Finale turtles + boss | **DEFER** — user Studio |

## Added steps before N7

1. **N6.1 Studio smoke** — Lawn Dart lob vs Roman Candle flat; foam bonus on Fire Lizard; net roots a grunt briefly; cancel flash after jab; swap within 2s of hurt → red punish Toast + flash; mash attack during recovery → no ghost swing (server `attackReadyAt`).  
2. **N6.2 Remotes Studio hygiene** — still user: delete stale `RequestJump` on long-lived places (N0.5…N5.2).  
3. **N6.3 Hitstop / ReduceMotion** — confirm Options Reduce motion still skips hitstop/shake/SwapBurst after extract.  
4. **N6.4 Ember / GREASY regression** — dodge with BonfireEmber still buffs next hits; GREASY oil resist on slicks.  
5. **N6.5 Art pipeline gate** — N7 may start only with real MeshPart asset IDs after upload; no invented `rbxassetid` placeholders (invariants will enforce).  
6. **N6.6 Blind feel** — optional 5-person check that dart arc ≠ candle shot before shipping N7 trailer stills.

## Gate to N7

N7 (art / anim) may start after N6.1 Studio smoke when possible: CombatFacade is thin, cancel/recovery sync live, weapon secondaries wired, invariants green, dialogue popup-only. Prefer real uploaded meshes only — never invent Mesh IDs in Lua.
