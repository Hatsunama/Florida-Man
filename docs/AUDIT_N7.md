# AUDIT — Phase N7 Mesh/anim pipeline (procedural polish, no fake IDs)

**Date:** 2026-09-04 (America/New_York)  
**Base:** `de34b17` → this commit  
**Plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md) Phase N7  
**Prior:** [`AUDIT_N6.md`](AUDIT_N6.md)  
**Spec:** [`ART_PIPELINE.md`](ART_PIPELINE.md)

## Acceptance

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Zero invented Mesh / Animation IDs in codebase | **PASS** | No `MeshId`/`AnimationId` rbxassetid literals; registry empty; invariants reject stubs |
| Mesh swap path when real kits exist | **PASS** | `ArtAssets.TryCloneMeshModel` → `EnemyFactory.tryMeshEnemy` / Steve hub |
| Procedural Part kits remain fallback | **PASS** | `ArtKit = InEngine_v3` crab/gator/Steve polish |
| AnimController safe fallbacks | **PASS** | `IsValidAssetId`; skill/swap poses; ReduceMotion scale |
| VFX polish without meshes | **PASS** | bash/grab arcs; death ring; particleBudget |
| N6.3 ReduceMotion hitstop/shake | **PASS** | Confirmed + extended (anim scale, VFX budget, SkillPattern soft) |
| Dialogue popup-only | **PASS** | No dialogue SFX/VO changes |
| `./scripts/check_invariants.sh` green | **PASS** | Prior + N7 asset-ID greps |
| Trailer still ≠ “default R15 in Parts town” | **PARTIAL** | InEngine_v3 kits improved; full Mesh_v1 **blocked** on uploads |
| Studio smoke / real Mesh import | **DEFER** | User Studio; agents do not open Studio |

## Task checklist

| # | Task | Result |
|---|------|:------:|
| 1 | Harden art pipeline docs + code paths for meshes/anims when IDs exist | **PASS** |
| 2 | Improve procedural/Part enemy & persona visuals | **PASS** (InEngine_v3) |
| 3 | AnimController safe fallbacks, no broken anim refs | **PASS** |
| 4 | VFX polish without fake mesh IDs | **PASS** |
| 5 | Fold N6.3 ReduceMotion hitstop/shake | **PASS** |
| 6 | AUDIT_N7 shippable vs blocked | **PASS** (this doc) |

## Shippable now (no Studio assets required)

| Item | Status |
|------|--------|
| `ArtAssets.lua` registry + `IsValidAssetId` / `TryCloneMeshModel` | Live |
| Empty Rojo `ReplicatedStorage.Assets.{Meshes,Animations}` | Live |
| Enemy Part kits `InEngine_v3` (mustard stripe, gator oil sheen/drip, death ring) | Live |
| Captain Steve Part kit (crest + stance legs) + mesh clone hook | Live |
| Persona `BodyColors` + `FM_PersonaHighlight` | Live (pre-existing, asserted) |
| Procedural attack/dodge/jump/skill/swap poses | Live |
| VFX bash/grab + ReduceMotion particle budget | Live |
| Invariants: no placeholder rbxassetid / no MeshId literals | Live |

## Blocked on real Studio uploads (asset gap list)

| Gap | Needed for | Notes |
|-----|------------|-------|
| MeshParts for BeachCrab / CrabKingBoss / DriveThruGator / OilGator / Spillfather | Mesh_v1 enemies | Place under `Assets.Meshes.<EnemyId>`; no Lua IDs |
| MeshPart `CaptainSteve` | Hub NPC Mesh_v1 | Same clone path |
| AnimationIds: Idle/Run/Jump/Attack1–3/Dodge/Skill/Swap per persona | Replace procedural poses | Paste **real** IDs into `ArtAssets.AnimationIds` only |
| SurfaceAppearance textures | Sand/sludge materials | Upload maps; not inventable |
| Marketplace 512 / 1920 thumbs | Soft launch store page | Publish step — not Lua |
| LOD MicroProfiler pass on mid Android | Budget PASS claim | Measure in Studio |

## Implementation map

| Area | Change |
|------|--------|
| `ArtAssets.lua` | Central empty registries; ID validation; mesh clone helper |
| `EnemyFactory` | `tryMeshEnemy`; InEngine_v3 tag; crab mustard; gator sheen; DeathPoof ring |
| `WorldBuilder` | Steve mesh try + crest/legs Part polish |
| `AnimController` | ArtAssets IDs only; skill/swap poses; ReduceMotion amplitude |
| `VFX` | particleBudget; bash/grab; SkillPattern soft under ReduceMotion |
| `init.client` | `AnimController.PlaySwap` on swap event |
| `default.project.json` | `Assets.Meshes` / `Assets.Animations` folders |
| `ART_PIPELINE.md` / `assets/README.md` | N7 honesty + live swap path |
| `check_invariants.sh` | N7 greps + stub ID bans |

## AUDIT_N6 “before N7” folded

| # | Item | Result |
|---|------|:------:|
| N6.1 | Studio smoke combat feel | **DEFER** — user Studio |
| N6.2 | Remotes Studio hygiene | **DEFER** — user |
| N6.3 | ReduceMotion hitstop/shake after extract | **PASS** — confirmed + extended |
| N6.4 | Ember / GREASY regression | **HOLD** — live play (code path unchanged this phase) |
| N6.5 | Art pipeline gate (real Mesh IDs only) | **PASS** — enforced; no fake IDs |
| N6.6 | Blind dart vs candle feel | **HOLD** — optional playtest |

## Added steps before N8

1. **N7.1 Studio mesh import (optional before soft launch)** — Upload ≥1 hero kit (Crab or Steve) to `Assets.Meshes`; confirm `ArtKit=Mesh_v1` at runtime; keep Part fallback.  
2. **N7.2 Animation upload (optional)** — BeachBurnout Attack1 real ID in `ArtAssets`; confirm procedural still used when empty.  
3. **N7.3 Thumbnail authoring** — 512 icon + primary 1920 still for Creative Hub (publish pack).  
4. **N7.4 LOD budget measure** — MicroProfiler hub + stage 1 on mid Android; trim particles if over.  
5. **N6.1 carry** — Studio combat smoke (dart vs candle, foam, net, cancel, punish, recovery) still user.  
6. **N8 gate** — Friends-only publish + Meta rejoin + funnel markers per PLAN_NEXT N8; Mesh_v1 **not** required to start N8 soft launch.

## Gate to N8

N8 (soft launch & telemetry) may start with **InEngine_v3** art: mesh/anim pipeline is wired and honest, invariants ban fake IDs, ReduceMotion intact, dialogue popup-only. Real Mesh_v1 / AnimationIds remain optional polish tracked in the asset gap list above — do not invent IDs to clear the gap.
