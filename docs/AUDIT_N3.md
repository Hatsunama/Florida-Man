# AUDIT — Phase N3 Catalog Honesty

**Date:** 2026-09-04 (America/New_York)  
**Base:** `e3328e2` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N3  
**Prior:** [`AUDIT_N2.md`](AUDIT_N2.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Every `special` string has exactly one code owner | **PASS** | `ember`→DoDodge/on-hit; `oilResist`→GREASY set; prior specials unchanged |
| Every weapon unlocks in-run or removed | **PASS** | All 28 `Weapons.List` ids stage-gated (+ BareHands starter) |
| No README “28 weapons” lie | **PASS** | Count still 28; all reachable |
| Pierce caps documented + enforced | **PASS** | Ranged ≤2; thrown 1 |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N3 catalog checks |
| Dialogue popup-only | **PASS** | No new VO/SFX dialogue paths |
| Studio smoke / Remotes hygiene | **DEFER** | User (no Studio from agents) |

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | BonfireEmber on-dodge damage buff (or rewrite) | **PASS** — implemented `special=ember` |
| 2 | GREASY/HUMID set text match code | **PASS** — HUMID rewrite; GREASY oil resist live |
| 3 | Weapon unlock table covers every `Weapons.List` id | **PASS** |
| 4 | Cap ranged pierce (1–2) vs thrown single | **PASS** — `RANGED_PIERCE_HITS=2` |
| 5 | `hoaCone` damage tick or remove | **PASS** — tick dmg 3 |
| 6 | Act 3–4 density / telegraph budget note | **PASS** — documented; MaxHostiles unchanged |
| 7 | Update `BALANCE_SHEET.md` | **PASS** |

## Implementation map

| Area | Change |
|------|--------|
| `Items.lua` | Ember special; honest set/item copy; GREASY `oilResist` |
| `Constants.lua` | `RANGED_PIERCE_HITS`, ember buff, `OIL_SLOW_MULT_RESIST`, `HOA_CONE_DAMAGE` |
| `Types.lua` / `RunContext` | `emberUntil`; `HasGreasyOilResist`; `OilResist` attr |
| `CombatFacade` | Ember buff on dodge + on-hit mult |
| `CombatService` | Pierce budget for ranged/thrown |
| `HazardService` | hoaCone tick; oil resist shorter slicks / half oil hazard dmg |
| `WorldBuilder` | hoaCone `HazardDamage` |
| `StageFlowService` | Multi-drop unlock table; empty stages filled; full catalog coverage |
| `BALANCE_SHEET.md` | N3 numbers |
| `check_invariants.sh` | N3 greps |

## Special → owner

| special | Owner |
|---------|--------|
| `aggro` | `RunContext.ApplyCharacterSpeed` → `AggroPull` |
| `stageHeal` | `StageFlowService` stage clear |
| `antiCorp` / `badge` | `RunContext.ComputeStats` flat stats |
| `paperCut` / `radio` / `ember` | `CombatFacade` on-hit / dodge |
| `sunburnFind` | `StageFlowService` |
| `absorb` | `CombatFacade.ApplyDamageToPlayer` |
| `lifesteal` | HEROIC set → `HasHeroicLifesteal` |
| `oilResist` | GREASY set → HazardService + speed mult |

## AUDIT_N2 “before N3” folded

| # | Item | Result |
|---|------|:------:|
| N2.1 | Studio smoke hub→1–3 + turtle | **DEFER** — user Studio |
| N2.2 | Offline DataStore Studio | **DEFER** — user Studio |
| N2.3 | CombatFacade trim | **LEAVE → N6** |
| N2.4 | Rate-limit tuning | **HOLD** — live play |
| N2.5 | Schema v2 | **LEAVE → N4** |
| N2.6 | Remotes Studio hygiene (`RequestJump`) | **DEFER** — user Studio |

## Added steps before N4

1. **N3.1 Studio smoke** — dodge with BonfireEmber → toast/feel +25% window; ranged pierce stops at 2; thrown pops on 1; walk into hoaCone takes tick damage; GREASY set (3 tags) mild slicks.  
2. **N3.2 Weapon unlock pass** — clear ConspiracyShack / CypressCathedral and confirm new unlocks appear in HUD cycle (1/2/3 / NEXT WPN).  
3. **N3.3 CombatFacade trim** — still N6; do not grow facade for settings.  
4. **N3.4 Schema v2** — N4 mute/text-speed migrate via `META_SCHEMA_VERSION`.  
5. **N3.5 Remotes Studio hygiene** — delete stale `RequestJump` on long-lived places (N0.5 / N1.5 / N2.6).  
6. **N3.6 Act4 telegraph feel** — if MaxHostiles=4 + puddles reads busy in Studio, drop early Act4 max to 3 (balance knob only).

## Gate to N4

N4 (options / a11y / dialogue UX) may start: catalog specials honest, pierce capped, unlocks complete, invariants green, dialogue policy intact. Prefer N3.1 Studio smoke before shipping mute/settings persist.
