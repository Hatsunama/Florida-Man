# AUDIT — Phase 6 Meta, Balance, Publish Readiness

**Date:** 2026-09-04 (America/New_York)  
**Commit:**   
**Base HEAD before work:** `c23ca71`  
**Scope:** DataStore meta, HazardService extract, balance sheet + Act1 retune, daily draft luck, publish pack, telegraph/enemy pooling, invariants. No Studio.

## Acceptance checklist

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Meta persists (deaths/sunburn/unlocks/settings/best stage) | **PASS** | `MetaService.lua` Load/Save; memory fallback when DataStore fails |
| Publish checklist exists | **PASS** | `docs/PUBLISH_CHECKLIST.md` |
| Balance sheet / Act1 not spongy | **PASS** | `docs/BALANCE_SHEET.md`; HP/stage 0.09; BeachCrab 24 / Hermit 34 |
| Daily luck ±5% drafts | **PASS** | `Balance.DailyLuckBonus` + draft toast |
| GameService split progress | **PARTIAL** | MetaService + HazardService extracted; GS still ~1685 lines (god-object debt) |
| Invariants green | **PASS** | 14/14 including Meta/Hazard/Daily/Pool/Publish |
| No Studio opened | **PASS** | Agent did not launch Studio |

## Must-ship tasks

| # | Task | Result | Notes |
|---|------|:------:|-------|
| 1 | DataStore MetaService | **PASS** | pcall Get/SetAsync; Studio memory; save on death/hub/leave; SyncSettings remote |
| 2 | Balance comments + sheet | **PASS** | BALANCE_SHEET DPS vs HP; light Act1 retune |
| 3 | Daily modifier | **PASS** | UTC seed ±5% luck on drafts; documented |
| 4 | Publish pack | **PASS** | Thumbnails sizes, synopsis, maturity, Rojo steps, KPIs |
| 5 | Performance pooling | **PASS** | FM_TelegraphPool + FM_EnemyPool; StreamingEnabled recommended in publish doc |
| 6 | Split GameService | **PARTIAL** | Meta + Hazard extracted; Hub/Draft/Run still in GS |
| 7 | Soft launch KPIs | **PASS** | FTUE 60s + D1 in PUBLISH_CHECKLIST |
| 8 | Invariants extended | **PASS** | MetaService, HazardService, DailyLuck, pool, publish |

## Service extract

| Module | Lines | Role |
|--------|------:|------|
| MetaService | ~242 | Profile persist |
| HazardService | ~220 | Hazards, soft-fall, turtle prompts |
| GameService | ~1685 | Still owns run loop, combat remotes, drafts, waves |

**Remaining god-object debt:** Draft/Newspaper remotes, TickWaves/MidGate, combat DoAttack/DoSkill/DoSwap, hub Steve shop — candidates for DraftService / HubService / RunService in a follow-up. Plan target `<400` lines **not** met honestly.

## Meta profile fields

- `deaths`, `sunburn`, `unlockedPersonas[]`, `bestStageIndex`
- `settings.ShakeEnabled`, `settings.ColorblindTelegraphs`
- Load on join → apply attrs; SyncSettings from HUD toggles

## Invariants

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
```

## Grades (post Phase 6)

| Area | Grade | Delta |
|------|:-----:|-------|
| Meta / retention | **B−** | Was F/none — DataStore + memory |
| Balance docs | **B** | Sheet + daily luck + Act1 retune |
| Publish readiness | **B−** | Checklist complete; no marketplace PNGs in repo |
| Architecture | **C+** | Two extracts; GS still large |
| Performance hygiene | **C+** | Pools exist; StreamingEnabled not forced in place file |

## Added steps after Phase 6

1. **P6.1 Studio DataStore** — enable API services; verify rejoin keeps sunburn/unlocks/settings.
2. **P6.2 Thumbnail art** — author 512 + 1920 assets; upload Creator Hub.
3. **P6.3 Further GS split** — HubService + DraftService to approach &lt;400 lines.
4. **P6.4 Soft launch** — friends-only; measure FTUE 60s funnel.
5. **P6.5 True production DataStore** — published place; monitor SetAsync failures.
