# Florida Man — Art Pipeline

**Phase:** N7 (mesh/anim pipeline hardened; Part kits ship until real uploads)  
**Date:** 2026-09-04 (America/New_York)  
**Honesty rule:** We do **not** invent MeshPart / Animation `rbxassetid://` values. Until real Studio uploads exist, gameplay ships **Part + SpecialMesh (built-in MeshType) + Material** kits tagged `ArtKit = "InEngine_v3"`.

---

## 1. Toolchain (Blender → FBX → Roblox)

| Step | Tool | Notes |
|------|------|-------|
| 1. Blockout | Blender 4.x | Keep origin at feet / root; +Y up export or Roblox-facing Z — pick one and stick to it |
| 2. Retopo / UV | Blender | Texel density ~256–512 px/m for mid props |
| 3. Export | FBX 7.4 binary | Apply modifiers; Forward −Z, Up Y; bake scale 0.01 if working in cm |
| 4. Import | Roblox Studio Asset Manager / 3D Importer | One MeshPart per LOD; weld under Model with PrimaryPart = root |
| 5. Materials | SurfaceAppearance | ColorMap + optional Normal/RoughnessMetalness; MetalnessMap only when needed |
| 6. Wire | Rojo `ReplicatedStorage.Assets.Meshes` **or** Studio-only folder | Lua clones by **name** via `ArtAssets.TryCloneMeshModel`; never hardcode fake IDs |
| 7. QA | Device + mid Android | LOD0 only near camera; LOD2 for far parallax |

### Naming

```
FM_<Role>_<Subject>_<Variant>_LOD<0-2>
```

Roles: `Enemy`, `NPC`, `Prop`, `Persona`, `VFX`, `UI`.

### Animation export

- R15-compatible Humanoid rig **or** custom Motor6D skeleton matching `EnemyFactory` bone names.
- Export actions: `Idle`, `Run`, `Jump`, `Dodge`, `Attack1`, `Attack2`, `Attack3`, `Skill`, `Swap`.
- Upload via Animation Editor → paste real AnimationId into `ArtAssets.AnimationIds` **only** after upload.
- `ArtAssets.IsValidAssetId` rejects empty / `rbxassetid://0` / short stubs / obvious placeholders. Empty → procedural fallback in `AnimController`.

---

## 2. Swapping Part kits for MeshParts (code path live)

**Today:** `EnemyFactory` / `WorldBuilder` build Part soup and set `ArtKit = "InEngine_v3"` (or `Mesh_v1` when a Studio kit is present).

**When meshes exist:**

1. Drop MeshPart models under `ReplicatedStorage.Assets.Meshes` (Studio; Rojo folder is empty scaffolding) named exactly like subject (`BeachCrab`, `CrabKingBoss`, `CaptainSteve`, `DriveThruGator`, `Spillfather`, …).
2. At build time: `ArtAssets.TryCloneMeshModel(def.id)` → if present, clone + place, set `ArtKit = "Mesh_v1"`, skip Part builder.
3. Keep Part builder as permanent fallback for Studio-less CI / Rojo smoke.

**Do not** delete Part kits until Mesh_v1 covers all slice enemies + hub NPC.  
**Do not** invent `rbxassetid://` MeshIds in Lua — clone by instance name only.

Module: `src/shared/ArtAssets.lua`

---

## 3. In-engine materials (SurfaceAppearance-like)

Roblox `SurfaceAppearance` needs uploaded textures. Until then we approximate with **Material + Color palettes**:

| Feel | Material | Typical use |
|------|----------|-------------|
| Sand | `Sand` / `SmoothPlastic` | Beach crabs, ground |
| Sludge | `Mud` | Oil gator, Spillfather chassis |
| Hazmat / metal | `Metal` | Drive-Thru collar, boss mech |
| Neon gas | `Neon` | Crowns, weak points, flame, mustard stripe |
| Glass / wet | `Glass` / `ForceField` | Slushie, eyes, oil sheen |
| Soft body | `Plastic` / `SmoothPlastic` | Steve feathers, cooler |

Particle **ColorSequence** decals stand in for painted markings (mustard stripe, oil drip, sand dust).

---

## 4. Hero kit targets (N7 cast)

| Subject | Builder | In-engine (InEngine_v3) | Mesh gate |
|---------|---------|-------------------------|-----------|
| Florida Man (player) | Default R15 + persona tint | `BodyColors` + `Highlight` from active persona | — |
| Captain Steve | `WorldBuilder._BuildHub` | Pelican spheres/wedges, crest, stance legs, feather fluff | `Assets.Meshes.CaptainSteve` |
| Beach Crab | `EnemyFactory.buildCrab` | Sand carapace, mustard neon stripe, Ball dome, Neon pupils | `Assets.Meshes.<EnemyId>` |
| Crab King | `buildCrab` miniboss | Tide crown + PointLight | same |
| Drive-Thru Gator | `buildGator` | Mud body, Metal collar, ForceField oil sheen, drip | same |
| Spillfather | `buildBoss` | Mud chassis, Metal claws, oil ColorSequence drip | same |
| Hub bonfire | `_BuildHub` | Cylinder logs, layered flame particles, warm PointLight | — |

---

## 5. Animation layer

Modules: `ArtAssets.lua` (registry) + `AnimController.lua` (play / procedural)

1. If `ArtAssets.GetAnimationId(personaId, clip)` returns a validated `rbxassetid://…`, `Humanoid:LoadAnimation` + play.
2. Else **procedural fallback:** Motor6D pose offsets (Waist / shoulders / Root). Poses: BeachBurnout slap, CrabKing pinch, dodge, jump, skill, swap.
3. `ReduceMotion` scales procedural pose amplitude (~35%).

**Registry:** fill `ArtAssets.AnimationIds` only after Studio upload. Empty strings are intentional.

---

## 6. VFX kit

`src/client/Controllers/VFX.lua` — `SwingSlash(hrp, facing, combo, vfxKind)`

Wired `weapon.vfx` strings:

| `vfx` | Arc |
|-------|-----|
| `punch` | Short neon fist burst |
| `slap` | Wide horizontal flip-flop arc |
| `dart` / thrown kinds | Lobbing streak |
| `firework` / ranged kinds | Flat spark trail |
| `bash` / `grab` | Distinct bash slash / claw grab |

`ReduceMotion`: particle budget quartered; HitSpark / SwapBurst skipped; SkillPattern soft ball only.

Server sets `character:SetAttribute("WeaponVfx", weapon.vfx)`.

---

## 7. UI image pack fallback

- Persona HUD icons: circular colored frames + accent glyph.
- Optional `ImageLabel`: `rbxasset://textures/ui/GuiImagePlaceholder.png` only — never fake marketplace icons.
- Real PNG pack → `assets/ui/` → Studio upload → replace Image IDs in a follow-up.

---

## 8. Thumbnail / loading screen spec

| Asset | Size | Copy / notes |
|-------|------|----------------|
| Experience icon | **512×512** | Bonfire silhouette + “FLORIDA MAN” wordmark |
| Thumbnails (up to 10) | **1920×1080** | Hub bonfire, Crab King, Drive-Thru Gator, Spillfather |
| Loading / splash | in-game ScreenGui | `LoadingGui.lua` — no marketplace ID required |

Marketplace Creative Hub upload is a **publish** step, not a Lua ID invent.

---

## 9. LOD / part-count budgets (slice stages)

| Stage | Index | Enemy peak | Soft part budget (active) | Notes |
|-------|------:|------------|---------------------------:|-------|
| Hub | 0 | 0 hostiles | ≤ 180 parts | Steve + bonfire + décor |
| Daytona Hangover | 1 | ~8 + Crab King | ≤ 450 | Sand particles low rate |
| Boardwalk Chaos | 2 | ~10 | ≤ 550 | Carts denser |
| Gas Station | 3 | ~12 | ≤ 650 | MidGate + oil props |

| LOD | Distance | Mesh tris (future) | Part kit rule |
|-----|----------|--------------------:|---------------|
| LOD0 | &lt; 40 studs | ≤ 8k | Full kit |
| LOD1 | 40–90 | ≤ 3k | Drop pupils / drip / secondary claws |
| LOD2 | &gt; 90 | ≤ 800 / billboard | Root + 1 silhouette part |

**VFX:** ≤ 3 ParticleEmitters emitting per player action; death poofs Debris ≤ 0.6s.

---

## 10. Asset ID registry (empty until real)

| Key | Type | ID | Notes |
|-----|------|----|-------|
| — | — | — | *No Mesh/Animation IDs checked in. Add rows only after Studio upload + `ArtAssets.IsValidAssetId` passes.* |

Code registry: `ArtAssets.AnimationIds` + `ArtAssets.MeshSubjects` (names only, not IDs).

---

## 11. Checklist before claiming Mesh_v1 done

- [ ] ≥6 slice characters use real MeshParts under `Assets.Meshes`
- [ ] BeachBurnout Attack1 AnimationId plays (validated ID in `ArtAssets`)
- [ ] SurfaceAppearance sand/sludge on ground or hero props
- [ ] Budgets measured on mid Android
- [ ] `./scripts/check_invariants.sh` still green
- [ ] Zero invented / placeholder `rbxassetid` in `src/`
