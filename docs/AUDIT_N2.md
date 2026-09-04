# AUDIT — Phase N2 Trust & Edge Hardening

**Date:** 2026-09-04 (America/New_York)  
**Base:** `c1d32dd` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N2  
**Prior:** [`AUDIT_N1.md`](AUDIT_N1.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Exploit IFrame attr still useless | **PASS** | Damage via `EnemyService._onPlayerHit` → `CombatFacade.ApplyDamageToPlayer`; `HasIFrames` server-table unchanged |
| Turtle cannot grant double sunburn/count | **PASS** | Attack-rescue removed; `TryRescue` debounce 1.5s + `Rescued` attr; single Prompt/Remote path |
| Studio offline DataStore: toast once, meta survives | **PASS*** | GetAsync/store fail → memory keep + one “Cloud save offline” toast; dirty/re-entrancy guards |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N2 trust/edge checks |
| Dialogue popup-only | **PASS** | No new VO/SFX dialogue paths |
| GameService ≤400 | **PASS** | 295 lines |
| No hub→stages 1–3 behavior regression | **PASS*** | Extract/harden only; Studio smoke not run (agent rule) |

\*Agent did not open Studio; offline DataStore path exercised by code review + memory fallback logic.

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Kill PendingDamage bus / server-authority hit path | **PASS** |
| 2 | Turtle single rescue path (debounce; no attack-rescue) | **PASS** |
| 3 | OilSlow ≠ Hangover (distinct mult; min-stack; no client double-apply) | **PASS** |
| 4 | Soft-fall: max 3 toasts/stage; snap to last solid ground | **PASS** |
| 5 | DataStore safe load/save, schema version, failure fallback | **PASS** |
| 6 | Double-save / re-entrancy guards; Meta owns PlayerRemoving save | **PASS** |
| 7 | Rate-limit RequestAttack/Skill/Dodge (token bucket) | **PASS** |
| 8 | MidGate + empty waves → never lock | **PASS** |
| N1.6 | Single `Remotes.InitServer` (init.server only) | **PASS** |

## Implementation map

| Area | Change |
|------|--------|
| `EnemyService` | `SetOnPlayerHit`; hit applies callback; `RESCUE_DEBOUNCE` on `TryRescue` |
| `CombatFacade` | Registers OnPlayerHit in Init; removes ally attack-rescue loop |
| `GameService` | PendingDamage poll removed; combat remote token buckets; leave clears run state only |
| `MetaService` | `schemaVersion`; dirty + `saving` re-entrancy; GetAsync fail keeps memory; run capturer on Unload; cloud-offline toast once |
| `RunContext` | Hangover + OilSlowUntil min-stack into authoritative `MoveSpeed` |
| `HazardService` | `OilSlowUntil` (not Hangover); soft-fall toast cap; `LastSolidX/Y` snap |
| `MovementController` | No client `hangoverMult` re-multiply (server MoveSpeed is final) |
| `StageFlowService` | MidGate empty `#waves` unlock; reset soft-fall / oil attrs on LoadStage |
| `Constants` / `Types` | `OIL_SLOW_MULT`, rescue/soft-fall/rate/schema constants; `MetaProfile.schemaVersion` |

## Invariants script (N2)

```
OK  … (all N0/N1 checks)
OK  PendingDamage gone
OK  OnPlayerHit callback
OK  CombatFacade registers OnPlayerHit
OK  No attack-rescue TryRescue
OK  Rescue debounce
OK  OilSlowUntil hazard
OK  OIL_SLOW_MULT distinct
OK  Hangover/OilSlow min-stack
OK  Meta schema version
OK  Meta dirty/re-entrancy
OK  Meta run capturer
OK  Cloud offline toast
OK  Combat remote rate limit
OK  Soft-fall toast cap
OK  Soft-fall solid sample
OK  MidGate empty waves unlock
OK  Client hangoverMult gone
OK  GameService <=400 (295)
```

## Dialogue policy (unchanged)

Conversations = Tagline / Toast / Newspaper only. Combat SFX retained.

## AUDIT_N1 “before N2” folded

| # | Item | Result |
|---|------|:------:|
| N1.1 | Studio smoke hub→1–3 | **DEFER** — still needs human Studio (no Studio this pass) |
| N1.2 | PendingDamage → OnPlayerHit | **PASS** — done this phase |
| N1.3 | CombatFacade size | **DEFER** — N6; still ~460 lines, GameService stays thin |
| N1.4 | RunContext vs Types | **HOLD** — single Types source kept; no re-divergence |
| N1.5 | Remotes folder RequestJump Studio delete | **DEFER** — Studio one-shot |
| N1.6 | Double InitServer | **PASS** — SetupRemotes no longer calls InitServer |

## Added steps before N3

1. **N2.1 Studio smoke** — hub → stages 1–3 + one turtle stage: Prompt-only rescue (attack must not count); MidGate lock/clear on stage ≥3 with waves; confirm hangover then oil slick do not stack-multiply speed.  
2. **N2.2 Offline DataStore Studio** — disable API Services / fail GetAsync: one cloud-offline toast; smash/sunburn survives session rejoin via memory until cloud returns.  
3. **N2.3 CombatFacade trim** — N6 moveset docs; avoid growing facade while adding catalog honesty.  
4. **N2.4 Rate-limit tuning** — live play may need burst/rate tweaks if laggy clients feel rejected (token bucket is conservative).  
5. **N2.5 Schema v2** — N4 settings (mute/text speed) should bump `META_SCHEMA_VERSION` / store name migrate path already stubbed via `schemaVersion` field.  
6. **N2.6 Remotes Studio hygiene** — still delete stale `RequestJump` instances on long-lived places (N0.5 / N1.5).

## Gate to N3

N3 (catalog honesty) may start: PendingDamage gone, turtle/OilSlow/DataStore hardened, invariants green, dialogue policy intact. Prefer N2.1 Studio smoke before BonfireEmber / pierce-cap balance changes.
