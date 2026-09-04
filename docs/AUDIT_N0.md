# AUDIT — Phase N0 Hygiene Lock

**Date:** 2026-09-04 (America/New_York)  
**Base:** `122b6e5` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N0

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Grep: zero `RequestJump` usage | **PASS** | Removed from `Remotes.NAMES`; `rg RequestJump src/` empty |
| Grep: Tagline has no `AudioDirector` | **PASS** | Visual typewriter only; invariant `absent` |
| PickDraftItem respects slots | **PASS** | `#items >= itemSlots` → toast + skip insert; still advances stage |
| `./scripts/check_invariants.sh` green + new checks | **PASS** | All prior Phase 0 checks + N0 dialogue/remote/spawn/types |

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Remove `RequestJump` | **PASS** |
| 2 | Wire EquipWeapon cycle (1/2/3 + HUD/mobile NEXT WPN) | **PASS** |
| 3 | Expand `Types.lua` (MetaProfile, WeaponKind, HazardKind, RunState) | **PASS** |
| 4 | Extend `check_invariants.sh` | **PASS** |
| 5 | Delete empty MetaService Studio block; empty hub Flame tick | **PASS** |
| 6 | Draft `itemSlots` + InputController suppress attack when FM_* UI open | **PASS** |
| 7 | SpawnLocation → X=18 (`SPAWN_X`) | **PASS** |

## Invariants script output (N0)

```
OK  lookAlong facing
OK  SPAWN_X = 18
OK  ClickablePrompt
OK  HasIFrames server
OK  CombatService require GS
OK  MobileControls
OK  SoundId smoke
OK  OilSlow
OK  MetaService module
OK  MetaService require GS
OK  HazardService require GS
OK  DailyLuckBonus
OK  Telegraph pool
OK  Publish checklist
OK  RequestJump absent
OK  Tagline no AudioDirector
OK  No SFX_SteveBeep play()
OK  EquipWeapon remote
OK  PickDraftItem itemSlots
OK  SpawnLocation SPAWN_X
OK  Types WeaponKind
OK  Types MetaProfile
OK  Types RunState
```

## Dialogue policy (locked)

- Conversations = Tagline / Toast / Newspaper popups only  
- No dialogue VO; `SFX_SteveBeep` / `SFX_Typewriter` blocked in AudioDirector; no play() call sites  
- Combat SFX retained  

## EquipWeapon wiring

- Server handler kept; client fires via keys **1 / 2 / 3** (catalog order among unlocked)  
- HUD **NEXT WPN** button + mobile **WPN**  
- `StateUpdate` now includes `unlockedWeapons`  

## Added steps before N1

1. **N0.1 Enemy drop slots** — `OnEnemyKilled` still uses `#items < math.max(itemSlots, 8)`; align to hard `itemSlots` in N1 DraftService or N3 catalog honesty.  
2. **N0.2 Draft when full** — client still shows draft UI even if slots full; optional skip-draft path / auto-continue when `itemSlots` saturated.  
3. **N0.3 Types adoption** — `GameService.RunState` / `MetaService.MetaProfile` still local exports; gradually `require(Types)` or re-export to avoid dual definitions.  
4. **N0.4 Mobile ATK VFX** — mobile still fires `RequestAttack` without local swing VFX; route through InputController tryAttack for parity.  
5. **N0.5 Remotes folder hygiene** — existing live `RequestJump` RemoteEvent instances in a long-lived Studio place won’t auto-delete; document one-time Studio cleanup or recreate Remotes folder.  

## Gate to N1

N1 (GameService split) may start: hygiene lock green, invariants script pass, no Studio required for this agent pass.
