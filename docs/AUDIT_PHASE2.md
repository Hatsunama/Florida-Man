# AUDIT — Phase 2 Art Pipeline (in-engine ceiling)

**Date:** 2026-09-04 (America/New_York)  
**Base:** Phase 1 `97c7bec` / slice `729f1fd`  
**Scope:** Pipeline docs + Part/SpecialMesh/Material/Animation **fallbacks** — **no invented MeshPart / Animation rbxassetids**

## Honesty first

| Claim from PLAN Phase 2 acceptance | Result | Reality |
|------------------------------------|:------:|---------|
| ≥6 gameplay characters use MeshParts in-slice | **FAIL (expected)** | No authored FBX/MeshParts exist in repo. Shipped `ArtKit = "InEngine_v2"` Part + **built-in** SpecialMesh (Sphere/Wedge/Cylinder/Brick) kits instead. |
| Attack animations play for starter persona | **PASS (fallback)** | `AnimController` plays uploaded IDs **if** present; BeachBurnout + CrabKing use **procedural Motor6D poses** until real AnimationIds are filled. |
| Marketplace-quality icon set in repo | **PARTIAL** | Circular persona-colored HUD icons + `rbxasset://textures/ui/GuiImagePlaceholder.png` frame fallback. No PNG pack / marketplace upload. Spec in `ART_PIPELINE.md`. |
| Perf budget measured on mid Android | **DOC ONLY** | LOD/part-count **table documented**; not measured in this agent box (no Studio device run). |

**What 100× art STILL requires:** real Blender meshes, Studio FBX import, SurfaceAppearance textures, uploaded AnimationIds per persona, UI PNG pack, Creative Hub thumbnails, device MicroProfiler pass.

**What we shipped as pipeline + in-engine ceiling:** docs, `assets/` convention, hero Part kits (Beach Crab, Crab King, Drive-Thru Gator, Spillfather, Captain Steve, hub bonfire), player persona BodyColors + Highlight tint, AnimController fallbacks, weapon-specific VFX for punch/slap/dart/firework, LoadingGui, HUD circles.

## Acceptance / tasks checklist

| Task | Result | Notes |
|------|:------:|-------|
| `docs/ART_PIPELINE.md` Blender→FBX→importer | **PASS** | Toolchain, naming, swap path, LOD budgets, thumbnail spec, empty ID registry |
| `assets/` placeholders + README | **PASS** | meshes/animations/textures/ui/templates |
| Hero kits without fake Mesh IDs | **PASS** | SpecialMesh built-in types only; Materials Sand/Mud/Metal/Neon/Glass/Plastic |
| SurfaceAppearance-like materials | **PASS** | Material palettes (true SurfaceAppearance needs uploads — deferred) |
| Animation layer AnimController | **PASS** | Empty ID registry + BeachBurnout/CrabKing procedural poses |
| VFX weapon.vfx punch/slap/dart/firework | **PASS** | Wired via `WeaponVfx` attribute + InputController |
| UI persona colored icon circles | **PASS** | Circular UICorner + rarity strokes retained |
| Thumbnail/loading spec + LoadingGui | **PASS** | Spec in ART_PIPELINE; `LoadingGui` ScreenGui (no marketplace) |
| LOD budget table | **PASS** | Hub + stages 1–3 soft part budgets |
| Phase 0 invariants green | **PASS** | `./scripts/check_invariants.sh` all 8 OK |
| No Studio / rbxlx open | **PASS** | Agent did not launch Studio |

## Grades (post Phase 2)

| Area | Grade | Delta |
|------|:-----:|-------|
| Art pipeline (process) | **B** | Was N/A — documented + folders |
| In-engine hero readability | **B** | Was B− — SpecialMesh + stronger palettes |
| Player persona identity | **B−** | Was C — BodyColors + Highlight tint |
| Animation | **C+** | Was D — procedural poses; real clips still missing |
| VFX catalog honesty | **B−** | Was C — punch/slap/dart/firework no longer lies |
| UI icons | **B−** | Was B− — circles + placeholder texture |
| Publish art (thumbs) | **D+** | Spec only; no marketplace assets |
| Phase 0 invariants | **B** | Still green |
| True MeshPart 100× art | **F** | Intentionally out of scope without assets |

## Added steps before Phase 3

1. **P2.1 Author Mesh_v1** — Beach Crab, Crab King, Steve, Drive-Thru Gator, Spillfather, player kit (or layered clothing) in Blender; import; fill ART_PIPELINE ID registry.
2. **P2.2 Upload Attack1 for BeachBurnout** — paste AnimationId into `AnimController.AnimationIds`; verify override of default Animate.
3. **P2.3 SurfaceAppearance pack** — sand / sludge / hazmat / neon gas textures under `assets/textures/`.
4. **P2.4 Device budget measure** — Studio MicroProfiler on mid Android vs table in ART_PIPELINE §9; cut particle rates if over.
5. **P2.5 UI PNG pack** — 8 persona icons + rarity frames; replace GuiImagePlaceholder.
6. **P2.6 Creative Hub thumbnails** — 512 icon + 1920×1080 stills per spec (publish step).
7. **P2.7 Mesh swap hook** — implement `ReplicatedStorage.Assets.Meshes` clone branch in EnemyFactory when kits exist (documented, not coded as dead require).
8. **P3 gate:** combat depth can start in parallel, but swap/attack juice will feel thin until P2.2.

## Gate to Phase 3

Phase 3 (combat depth) may start with current fallbacks. **Do not** block Phase 3 on MeshParts. Prefer uploading BeachBurnout Attack1 before claiming trailer-ready combat.

## Files touched (high level)

- **New:** `docs/ART_PIPELINE.md`, `docs/AUDIT_PHASE2.md`, `assets/**`, `src/client/Controllers/AnimController.lua`, `src/client/UI/LoadingGui.lua`
- **Server:** `EnemyFactory.lua`, `WorldBuilder.lua`, `GameService.lua` (persona look + WeaponVfx)
- **Client:** `VFX.lua`, `InputController.lua`, `MovementController.lua`, `HUD.lua`, `init.client.lua`
