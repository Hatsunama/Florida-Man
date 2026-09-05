# Florida Man — PLAN_NEXT FINAL Scorecard (N0–N8)

**Date:** 2026-09-04 (America/New_York)  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md)  
**Layers baseline:** [`AUDIT_LAYERS.md`](AUDIT_LAYERS.md)  
**Prior 0–6 scorecard:** [`AUDIT_FINAL.md`](AUDIT_FINAL.md)  
**Tip base before N8:** `7e6c37e` (N7)  
**Soft-launch art:** **InEngine_v3** (Mesh_v1 optional)

---

## Phase commit chain (PLAN_NEXT)

| Phase | Name | Audit | Code result |
|------:|------|-------|-------------|
| **N0** | Hygiene lock | [`AUDIT_N0.md`](AUDIT_N0.md) | **PASS** — RequestJump culled, draft slots, dialogue invariants |
| **N1** | GameService split | [`AUDIT_N1.md`](AUDIT_N1.md) | **PASS** — Orchestrator ≤400; Hub/Draft/StageFlow/CombatFacade |
| **N2** | Trust & edges | [`AUDIT_N2.md`](AUDIT_N2.md) | **PASS** — PendingDamage gone; turtle/OilSlow/DataStore/rate limits |
| **N3** | Catalog honesty | [`AUDIT_N3.md`](AUDIT_N3.md) | **PASS** — specials owned; 28 weapons unlock; pierce caps |
| **N4** | Options / dialogue UX | [`AUDIT_N4.md`](AUDIT_N4.md) | **PASS** — mute buses, text speed, reduce motion, schema v2 |
| **N5** | Level verbs | [`AUDIT_N5.md`](AUDIT_N5.md) | **PASS** — per-act verbs; turtle escort; MidGate Tagline |
| **N6** | Combat depth | [`AUDIT_N6.md`](AUDIT_N6.md) | **PASS** — Attack/Skill/Swap extract; cancel/punish; recovery sync |
| **N7** | Art / anim pipeline | [`AUDIT_N7.md`](AUDIT_N7.md) | **PASS*** — pipeline + InEngine_v3; Mesh_v1 **blocked** on uploads |
| **N8** | Soft launch / KPIs | [`AUDIT_N8.md`](AUDIT_N8.md) | **PASS*** — Funnel + publish pack; **live** publish/playtest **DEFER** |

\*Agent rule: Studio smoke / mesh import / Remotes place hygiene left to user.

---

## Pass / fail summary

| Phase | Plan acceptance | Invariants | Dialogue popup-only | Studio-dependent |
|------:|:---------------:|:----------:|:-------------------:|:----------------:|
| N0 | **PASS** | **PASS** | **PASS** | DEFER smoke |
| N1 | **PASS** | **PASS** | **PASS** | DEFER smoke |
| N2 | **PASS** | **PASS** | **PASS** | DEFER DataStore live |
| N3 | **PASS** | **PASS** | **PASS** | DEFER catalog smoke |
| N4 | **PASS** | **PASS** | **PASS** | DEFER options rejoin live |
| N5 | **PASS** | **PASS** | **PASS** | DEFER verb playtest |
| N6 | **PASS** | **PASS** | **PASS** | DEFER combat feel |
| N7 | **PARTIAL** (no Mesh_v1) | **PASS** | **PASS** | DEFER mesh upload |
| N8 | **PARTIAL** (code ready; live DEFER) | **PASS** | **PASS** | DEFER friends publish |

**Overall PLAN_NEXT (code):** **PASS for soft-launch-ready InEngine_v3 build.**  
**Overall PLAN_NEXT (production live):** **HOLD** until friends-only publish + Meta rejoin + uncoached 1–3 clear.

---

## Grade delta (honest)

| Area | After Phase 6 (`AUDIT_FINAL`) | After N8 | Note |
|------|:-----------------------------:|:--------:|------|
| Architecture | C+ | **B−** | GS ~308 lines; services extracted |
| Catalog honesty | (thin) | **B** | N3 specials/weapons |
| Dialogue | Mixed → policy | **B** | Popup-only locked N0/N4/N8 |
| Settings / a11y | 2 toggles | **B** | Mute / text speed / reduce motion |
| Edge hardness | Soft | **B** | N2 tests in invariants |
| Levels | C−/B− | **B−** | N5 verbs |
| Combat | B− | **B** | N6 facade + secondaries |
| Art | C− | **C+ / B− w/ Mesh** | InEngine_v3 shippable; Mesh_v1 optional |
| Production / telemetry | KPI notes only | **B− code** | FunnelService; live charts DEFER |

---

## Architecture snapshot (N8)

| Module | ~Lines | Owns |
|--------|------:|------|
| `GameService` | 308 | InitPlayer, remotes, tick, Funnel join/watch |
| `CombatFacade` | 125 | Damage/death + delegates |
| `FunnelService` | 169 | Soft-launch KPIs |
| `StageFlowService` | 558 | Stages / MidGate / Cold One / credits |
| `HubService` | 174 | StartRun / Steve / smash-upgrade |
| `DraftService` | 112 | Newspaper → draft |
| `MetaService` | 382 | DataStore v2 meta |

---

## Remaining blockers (tell the user)

1. **Friends-only publish** + enable API Services; confirm Meta rejoin on published place.  
2. **External playtest:** clear stages 1–3 in ≤15 min uncoached; watch `[FM_FUNNEL]` / `ftue_60s`.  
3. **Optional Mesh_v1** — upload real kits; never invent rbxassetid.  
4. **Marketplace thumbs** 512 + 1920.  
5. **Studio Remotes hygiene** — delete orphan `RequestJump` if present in old place.  
6. **LOD / MicroProfiler** on mid Android before wide public.

---

## How to run soft launch

| Step | Action |
|------|--------|
| Pull | `git pull` on `/workspace/Florida-Man` or local clone |
| Invariants | `./scripts/check_invariants.sh` |
| Sync | `rojo serve` → Studio plugin **or** `rojo build -o FloridaMan.rbxlx` |
| Smoke | [`SMOKE_CHECKLIST.md`](SMOKE_CHECKLIST.md) |
| Publish | [`PUBLISH_CHECKLIST.md`](PUBLISH_CHECKLIST.md) · KPIs [`KPI.md`](KPI.md) |
| Funnel | Filter Output for `FM_FUNNEL` |

**Do not** open Studio from automation agents.
