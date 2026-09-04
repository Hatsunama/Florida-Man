# AUDIT — Phase 3 Combat Depth (Skul-like swap mastery)

**Date:** 2026-09-04 (America/New_York)  
**Commit:** `d81346b`  
**Base HEAD before work:** `05f5a54`  
**Scope:** CombatService ownership, weapon kinds, persona movesets, swap mastery, distinct skills, item specials, boss hyper armor, anti-spam docs. No Studio.

## Acceptance checklist

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Blind-test: 3 weapons behave differently in **code paths** | **PASS** | `weapon.kind` branches in `GameService.DoAttack`: `melee` → `CombatService.InLaneMelee`; `ranged` → `CombatService.SpawnProjectile(kind="ranged")` flat lane Part; `thrown` → arcing Y parabola then hit. `WeaponKind` + `WeaponVfx` attributes set. |
| Catalog specials match code (no dead specials) **OR** removed | **PASS** | All non-empty `Items.lua` specials wired: `aggro`, `stageHeal`, `antiCorp`, `paperCut`, `sunburnFind`, `radio`, `absorb`, `badge`. Set bonus `HEROIC` → `lifesteal` on hit. Empty `special=""` are stat-only (honest). |
| IFrame still server-authoritative | **PASS** | `CombatService.HasIFrames` table; `ApplyDamageToPlayer` ignores client attrs. `IFrameVFX` / `ShieldAbsorbVFX` are juice only. |
| Invariants 8/8 | **PASS** | `./scripts/check_invariants.sh` all OK |
| Added steps before Phase 4 | **PASS** | See below |
| No Studio / rbxlx open | **PASS** | Agent did not launch Studio |

## Must-ship tasks

| # | Task | Result | Notes |
|---|------|:------:|-------|
| 1 | CombatService real owner | **PASS** | Hit validation helpers, recovery (`MarkAttack` per moveset), knockback (`ApplyKnockback` ALV preferred / PivotTo for Anchored kits), cancel-window comments, skill/swap rate mirrors, projectiles, shield absorb, lingering hitbox. `DoAttack`/`DoSkill`/`DoSwap` call shared `hitEnemy` → `EnemyService.ApplyDamage`. |
| 2 | Weapon kinds differ | **PASS** | melee / ranged / thrown distinct paths + distinct client VFX groups |
| 3 | Persona 3-hit movesets | **PASS** | `CombatService.MOVESETS` — BeachBurnout snappy vs CrabKing slower heavy pinch; recovery/range/knock/dmg per combo index |
| 4 | Swap mastery | **PASS** | HUD swap CD (serverNow sync); swap-attack mult 1.55 + toast/VFX; punish bonus if swap ≤2s after hurt |
| 5 | Skills distinct gameplay | **PASS** | Turtle = `SetShieldAbsorb` counter; Snake = 2s linger hitbox; Cart = `SetIFrames` armor frames on dash |
| 6 | Item specials | **PASS** | Wired (see table below) — no catalog lies removed needed |
| 7 | Boss hyper armor on phase flip | **PASS** | `HyperArmorUntil` 0.6s; skip flinch + skip knockback during window |
| 8 | Anti-spam | **PASS** | Attack recovery + skill/swap CD (+ CombatService mirrors). Documented in CombatService header |

## Item specials matrix

| special | Items | Code path |
|---------|-------|-----------|
| `aggro` | LiveBait | `AggroPull` attr → enemies treat player as closer |
| `stageHeal` | NoveltyMug, DewKoozie | stage clear heal (pre-existing) |
| `antiCorp` | TurtleSticker | `computeStats` damage bump |
| `paperCut` | HOACitation, HeadlinePressPass | on-hit crit-ish roll |
| `sunburnFind` | GatorSkinWallet | on-kill sunburn gain |
| `radio` | RadioCollar | bonus vs `OilGator` |
| `absorb` | SpillAbsorbent, RedTideFilter, OilProofBoots | incoming damage ×0.75 |
| `badge` | LabBadge | `computeStats` HP/dmg |
| `lifesteal` | HEROIC set (3) | heal on hit via `hasHeroicLifesteal` |

## Blind-test note (weapons)

A playtester reading only combat events / watching Parts should see:

1. **Melee (Bare Hands / Flip-Flop)** — instant lane cone; no projectile Part named `FM_*Proj`.
2. **Ranged (Roman Candle / NetGun)** — `FM_RangedProj` Neon Part travels flat along lane; damages on overlap.
3. **Thrown (Lawn Dart / Traffic Cone)** — `FM_ThrownProj` arcs in Y then pops on first hit.

## Anti-spam / cancel windows (doc)

- **Attack:** `CombatService.CanAttack` / `MarkAttack` with persona moveset recovery ÷ attackSpeed×weapon.speed.
- **Skill / Swap:** `skillReadyAt` / `swapReadyAt` on RunState **and** `CombatService.MarkSkill` / `MarkSwap` mirrors; early remotes are no-ops.
- **Cancel route:** Dodge and swap may fire during attack recovery (own CDs) — intentional Skul-like escape. Attack does **not** cancel skill CD.

## Grades (post Phase 3)

| Area | Grade | Delta |
|------|:-----:|-------|
| Combat ownership | **B+** | Was C — CombatService owns hit helpers / projectiles / absorb |
| Weapon identity | **B** | Was D — kinds actually branch |
| Persona movesets | **B−** | Was D — BeachBurnout ≠ CrabKing timings |
| Swap mastery | **B** | Was C — HUD CD + punish bonus |
| Skills (gameplay) | **B** | Was D — shield/summon/cart not VFX-only |
| Item catalog honesty | **A−** | Was C — specials wired |
| Boss phase readability | **B−** | Hyper armor on flip |
| Exploit / i-frame | **A−** | Still server table |

## Added steps before Phase 4

1. **P3.1 Studio smoke** — equip Roman Candle / Lawn Dart / Bare Hands; confirm three paths; verify Turtle absorb toast, Snake linger Part, Cart dash i-frames.
2. **P3.2 Projectile polish** — pool Parts; pierce rules for ranged; thrown AoE pop option; sync client predictive trail to server projectile.
3. **P3.3 Moveset authoring** — expose movesets in `Personas.lua` data (currently CombatService table); tune with anim lengths once Attack1–3 IDs exist (P2.2).
4. **P3.4 Swap meter optional** — consider charge meter instead of flat CD for skilled players (PLAN optional).
5. **P3.5 Damage number tiers** — light/medium/heavy audio layers still thin; hook StageSounds on hit weight.
6. **P3.6 Unanchor experiment** — if enemy roots ever unanchor, ALV knockback path activates; measure vs PivotTo readability.
7. **P4 gate:** world set-pieces can start; do not expand catalog until Studio confirms weapon/skill feel.

## Gate to Phase 4

Phase 4 (world & story) may start. Prefer P3.1 Studio confirmation before claiming trailer-ready combat. Mesh/anim from Phase 2 still improve juice but are not blockers for combat logic.

## Files touched

- **New:** `docs/AUDIT_PHASE3.md`
- **Server:** `CombatService.lua` (rewrite), `GameService.lua`, `EnemyService.lua`
- **Shared:** `Constants.lua`, `Personas.lua` (skill copy)
- **Client:** `HUD.lua` (swap/skill CD), `VFX.lua`, `init.client.lua`
