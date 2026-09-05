# Florida Man — Soft-launch KPIs & funnel (N8)

**Date:** 2026-09-04 (America/New_York)  
**Art kit for soft launch:** `InEngine_v3` (Mesh_v1 **not** required)  
**Module:** `src/server/FunnelService.lua`

## Policy — no fake telemetry secrets

| Allowed | Forbidden |
|---------|-----------|
| `AnalyticsService:LogCustomEvent` (pcall) | Invented API keys / webhook URLs |
| Structured Output: `[FM_FUNNEL] event uid=…` | Third-party SDKs without review |
| Creator Dashboard retention / session charts | Client-trusted “I cleared FTUE” economy grants |
| MetaService `bestStageIndex` / `deaths` | Selling meta currency for Robux without compliance |

If AnalyticsService is unavailable in Studio, markers still print to Output — that is enough for friends-only smoke.

## Funnel markers

| Event | When | Once / session? |
|-------|------|:---------------:|
| `session_join` | `GameService.InitPlayer` | join |
| `hub_start` | Bonfire Start Run | each run |
| `cold_one` | Florida Dew walkover | once |
| `ftue_60s` | Emitted on `cold_one`; `ok=1` if ≤60s since hub_start | once |
| `stage3_clear` | Finish stage index 3 (Gas Station of Legends) | once |
| `death` | `CombatFacade.KillPlayer` | each |
| `midgate_lock` / `midgate_clear` | MidGate room lock cycle | each |
| `draft_open` / `draft_pick` | Item draft UI | each |
| `softlock_suspect` | MidGate locked ≥90s **or** draft open ≥120s | once per where |
| `run_credits` | Full clear credits | each clear |

## KPI targets (soft launch)

| KPI | Target | How to read |
|-----|--------|-------------|
| **FTUE 60s** | ≥70% `ftue_60s ok=1` among first-run players who reach Cold One | Funnel prints + Creator Analytics custom events |
| **Stages 1–3 uncoached** | External player ≤15 min | Manual friends-only playtest |
| **D1 return** | Track unique return next UTC day | Creator Dashboard + Meta `bestStageIndex` / deaths on rejoin |
| **Softlock rate** | Investigate any `softlock_suspect` cluster | Output / custom events |
| **Crash / disconnect** | Investigate if >2% sessions | Creator Analytics |

## Studio / publish verification

1. Friends-only publish; **Enable Studio Access to API Services** for DataStore tests; published place uses real DataStores.
2. Rejoin: Options (mute / text speed / shake) restore; Meta sunburn/deaths survive when cloud OK.
3. Play → Output filter `FM_FUNNEL` → confirm `hub_start` → `cold_one` → (optional) `stage3_clear`.
4. Leave MidGate locked without clearing hostiles ~90s → expect `softlock_suspect where=midgate` (dev watch only).

## Deferred (user Studio — agents do not open Studio)

- Live soft-launch playtest with external player
- Mesh_v1 upload + marketplace 512/1920 thumbs
- Remotes folder hygiene if an old place still has leftover `RequestJump` instance (code already removed from `Remotes.NAMES`)
- Confirm Analytics charts populate for custom events on the published universe
