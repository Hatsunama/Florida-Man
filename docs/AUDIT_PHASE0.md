# AUDIT — Phase 0 Playability Lock

**Date:** 2026-09-04  
**Commit:** (see git log after push)  
**Base plan:** `docs/PLAN_100X.md` Phase 0

## Acceptance criteria

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Server-authoritative i-frames | **PASS** | `CombatService.SetIFrames/HasIFrames`; ApplyDamageToPlayer + EnemyService telegraph hits use HasIFrames |
| DoAttack facing precedence fixed | **PASS** | Uses `CombatService.InLaneMelee` (point-blank ≤2.5 or facing+range) |
| CombatService owned | **PASS** | I-frames, recovery, melee test, knockback helpers; GameService requires it |
| Server attack recovery | **PASS** | `CanAttack` / `MarkAttack` 0.22s |
| Audio smoke SoundIds | **PASS** | StageSounds assigned `rbxasset://sounds/...` placeholders |
| Mobile on-screen buttons | **PASS** | `MobileControls.lua` ATK/SKILL/DASH/USE when TouchEnabled |
| OilSlow ≠ Hangover | **PASS** | Hazards set `OilSlow` |
| Invariants doc + script | **PASS** | `PlayabilityInvariants.md`, `SMOKE_CHECKLIST.md`, `check_invariants.sh` |

## Grades (post Phase 0)

| Area | Grade | Delta |
|------|:-----:|-------|
| Security (i-frames) | B | Was F (client attr trust) |
| Combat ownership | C+ | Was D+ orphan |
| Audio | D | Was F — placeholders only, not designed mix |
| Mobile | C | Was F — ugly buttons exist |
| Invariants | B | Documented + greppable |

## Added steps before Phase 1

1. **P0.1 PendingDamage bridge** — EnemyService still sets PendingDamage attributes; ensure GameService tick applies damage only through ApplyDamageToPlayer (already HasIFrames). Verify no duplicate damage path bypasses CombatService.
2. **P0.2 Client dodge race** — Client dashes before server SetIFrames; consider client predicting VFX only and slightly longer server i-frame, or FireServer dodge before impulse.
3. **P0.3 Weapon keys 1–3** still stubs — either wire or remove (Phase 3 owns weapons; add Phase 1 note: hide stubs from UX).
4. **P0.4** Confirm `rbxasset://sounds/*` play in current Studio (some engine paths deprecate); swap to rbxassetid toolbox IDs if silent in Studio.

## Gate to Phase 1

Phase 1 (vertical slice) may start after: invariants script green + Studio smoke items 1–6 manually checked by someone with Studio.
