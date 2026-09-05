# AUDIT — Phase N8 Soft launch / KPIs

**Date:** 2026-09-04 (America/New_York)  
**Base:** `7e6c37e` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N8  
**Prior:** [`AUDIT_N7.md`](AUDIT_N7.md)  
**KPIs:** [`KPI.md`](KPI.md) · Publish: [`PUBLISH_CHECKLIST.md`](PUBLISH_CHECKLIST.md)  
**Final scorecard:** [`AUDIT_PLAN_NEXT_FINAL.md`](AUDIT_PLAN_NEXT_FINAL.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Soft-launch readiness docs (Community Standards, Dew, dialogue, playability, KPI stubs) | **PASS** | PUBLISH + KPI + PlayabilityInvariants N8 |
| Roblox-safe funnel / KPI hooks (no fake secrets) | **PASS** | `FunnelService` → AnalyticsService pcall + `[FM_FUNNEL]` prints |
| Markers: hub_start, cold_one, stage3_clear, death | **PASS** | + midgate/draft/ftue_60s/softlock_suspect/run_credits |
| SMOKE + PUBLISH refreshed for N0–N8 | **PASS** | Deferred Studio items listed |
| Loading / Credits / options polish | **PASS** | Loading policy tip; Credits dismiss; Options already N4 |
| Mesh_v1 not required | **PASS** | Soft launch on **InEngine_v3** |
| Dialogue popup-only | **PASS** | No dialogue SFX/VO added |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N8 Funnel/KPI checks |
| Friends-only publish + live Meta rejoin | **DEFER** | User Studio / Creator Hub |
| External player clears 1–3 in ≤15 min | **DEFER** | User playtest |
| DataStore confirmed on published place | **DEFER** | User — code path ready (Meta v2) |

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Soft-launch readiness (checklist / standards / invariants) | **PASS** |
| 2 | FunnelService KPI markers (Roblox-safe) | **PASS** |
| 3 | SMOKE_CHECKLIST + PUBLISH_CHECKLIST refresh | **PASS** |
| 4 | Loading / Credits polish | **PASS** |
| 5 | Document deferred Studio items | **PASS** |
| 6 | Final PLAN_NEXT scorecard N0–N8 | **PASS** — `AUDIT_PLAN_NEXT_FINAL.md` |

## Implementation map

| Area | Change |
|------|--------|
| `FunnelService.lua` | Session funnel, FTUE 60s, MidGate/draft softlock watch, Analytics + Output |
| `HubService` | `hub_start` |
| `StageFlowService` | `cold_one`, `stage3_clear`, midgate_*, `run_credits` + credit policy lines |
| `CombatFacade` | `death` |
| `DraftService` | `draft_open` / `draft_pick` |
| `GameService` | OnJoin / WatchSoftlocks / Unload (≤400 lines preserved) |
| `LoadingGui` | Tagline + Dew / dialogue / soft-launch tip |
| `Credits` | Tap/Esc dismiss + popup-only hint |
| `docs/KPI.md` | Marker table + no-secrets policy |
| `PUBLISH` / `SMOKE` / `PlayabilityInvariants` | N8 refresh |
| `check_invariants.sh` | N8 greps |

## Deferred Studio items (user)

| Item | Why deferred |
|------|----------------|
| Friends-only publish + API Services | Requires Creator Hub / Studio |
| Live Meta rejoin proof on published place | Needs real DataStore |
| External uncoached 1–3 clear ≤15 min | Human playtest |
| Mesh upload / Mesh_v1 / AnimationIds | Asset gap — see AUDIT_N7 |
| Marketplace 512 / 1920 thumbs | Not in repo |
| Remotes hygiene (`RequestJump` leftover instance) | Code already culled; old place files may still have orphan RemoteEvent |
| Analytics chart confirmation | Universe-side after publish |
| LOD MicroProfiler mid Android | Studio measure |

## Gate after N8

Code soft-launch pack is **shippable on InEngine_v3**. Production B− claim waits on deferred live checks above. Do not invent Mesh IDs or telemetry secrets to close gaps.
