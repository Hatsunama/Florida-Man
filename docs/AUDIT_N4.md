# AUDIT — Phase N4 Options / a11y / dialogue UX

**Date:** 2026-09-04 (America/New_York)  
**Base:** `251e76a` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N4  
**Prior:** [`AUDIT_N3.md`](AUDIT_N3.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Mute SFX → combat silent; Tagline still readable | **PASS** | `MuteSFX` / `MuteMaster` zero SFX+UI groups; Tagline popup-only |
| Instant text speed skips typewriter loop | **PASS** | `TextSpeed=instant` → delay 0; full text immediate |
| Rejoin restores settings (DataStore or memory) | **PASS** | Schema v2 persist + attr apply on Load; memory fallback |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N4 checks |
| Dialogue popup-only | **PASS** | Tagline no AudioDirector; Newspaper silent open; UI click on continue only |
| Studio smoke / Remotes hygiene | **DEFER** | User (no Studio from agents) |
| CombatFacade trim | **LEAVE → N6** | Per N3.3 / user scope |

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Settings panel: Shake, CB tele, Master/SFX/Ambience mute, Reduce motion, Tagline text speed | **PASS** — HUD Options drawer |
| 2 | Persist via MetaService schema v2 (`FloridaMan_Meta_v2` + v1 migrate) | **PASS** |
| 3 | Newspaper/Steve: popup text; optional UI click only | **PASS** — Newspaper open sting removed |
| 4 | Mobile settings hit targets ≥44px | **PASS** — Options btn + rows 44–48px |
| 5 | Readable Tagline + dismiss/skip | **PASS** — tap/click/Esc; typewriter skip then dismiss |
| 6 | Reduce motion tonedown hitstop / shake / land squash / VFX | **PASS** |

## Implementation map

| Area | Change |
|------|--------|
| `Settings.lua` | MuteMaster/MuteSFX/MuteAmbience, ReduceMotion, TextSpeed cycle + delays |
| `Constants.lua` | `META_SCHEMA_VERSION = 2` |
| `Types.lua` | MetaProfile.settings expanded |
| `MetaService` | Store `FloridaMan_Meta_v2`; legacy `v1` GetAsync migrate; sanitize new fields |
| `GameService` | SyncSettings whitelist bool keys + TextSpeed; Save after update |
| `AudioDirector` | `ApplyMute`; attr listeners; Play early-out when muted |
| `Tagline` | Larger readable panel; text speed; skip/dismiss; still no AudioDirector |
| `Newspaper` | Silent open; `SFX_UIClick` on continue only |
| `HUD` | Options drawer (hub/pause-adjacent); ≥44px targets |
| `CameraController` | ReduceMotion skips shake + land squash bump |
| `MovementController` | ReduceMotion skips Hitstop |
| `VFX` | ReduceMotion skips HitSpark / SwapBurst |
| `InputController` | Block combat input while `FM_Tagline` / `FM_Options` open |
| `check_invariants.sh` | N4 greps |

## Settings → consumer

| Setting | Consumer |
|---------|----------|
| `ShakeEnabled` | `CameraController.Shake` |
| `ColorblindTelegraphs` | `EnemyService` tele stripes |
| `MuteMaster` | `AudioDirector` all groups → 0 |
| `MuteSFX` | SFX + UI groups |
| `MuteAmbience` | Ambience beds |
| `ReduceMotion` | Hitstop / shake / land squash / HitSpark / SwapBurst |
| `TextSpeed` | `Tagline` typewriter delay (`slow`/`normal`/`instant`) |

## AUDIT_N3 “before N4” folded

| # | Item | Result |
|---|------|:------:|
| N3.1 | Studio smoke (ember / pierce / hoaCone / GREASY) | **DEFER** — user Studio |
| N3.2 | Weapon unlock pass in Studio | **DEFER** — user Studio |
| N3.3 | CombatFacade trim | **LEAVE → N6** |
| N3.4 | Schema v2 mute/text-speed | **PASS** — this phase |
| N3.5 | Remotes Studio hygiene (`RequestJump`) | **DEFER** — user Studio |
| N3.6 | Act4 telegraph feel knob | **HOLD** — live play |

## Added steps before N5

1. **N4.1 Studio smoke** — Options panel: Mute SFX → swings silent; Instant text → Tagline fills at once; Reduce motion → no hitstop/shake; rejoin restores toggles.  
2. **N4.2 Schema migrate** — with API Services on: old `FloridaMan_Meta_v1` profile loads into v2 store on first Save.  
3. **N4.3 Remotes Studio hygiene** — still user: delete stale `RequestJump` on long-lived places (N0.5 / N1.5 / N2.6 / N3.5).  
4. **N4.4 CombatFacade trim** — still N6; do not grow facade for level verbs.  
5. **N4.5 N3.1 catalog smoke** — still deferred: BonfireEmber / pierce / hoaCone / GREASY in Studio before balance knobs.  
6. **N4.6 Act2 verb spike** — N5 starts with pad-only / soft-fall water timeout after StageFlow stable.

## Gate to N5

N5 (level verb differences) may start: options/mute/text-speed/reduce-motion persisted on schema v2, dialogue popup-only confirmed, invariants green. Prefer N4.1 Studio smoke before shipping Act verbs. Leave CombatFacade trim for N6; Studio remotes hygiene for user.
