# Florida Man — Art Pipeline

**Phase:** 2 (in-engine ceiling + pipeline docs)  
**Date:** 2026-09-04 (America/New_York)  
**Honesty rule:** We do **not** invent MeshPart / Animation `rbxassetid://` values. Until real Studio uploads exist, gameplay ships **Part + SpecialMesh (built-in MeshType) + Material** kits tagged `ArtKit = "InEngine_v2"`.

---

## 1. Toolchain (Blender → FBX → Roblox)

| Step | Tool | Notes |
|------|------|-------|
| 1. Blockout | Blender 4.x | Keep origin at feet / root; +Y up export or Roblox-facing Z — pick one and stick to it |
| 2. Retopo / UV | Blender | Texel density ~256–512 px/m for mid props |
| 3. Export | FBX 7.4 binary | Apply modifiers; Forward −Z, Up Y; bake scale 0.01 if working in cm |
| 4. Import | Roblox Studio Asset Manager / 3D Importer | One MeshPart per LOD; weld under Model with PrimaryPart = root |
| 5. Materials | SurfaceAppearance | ColorMap + optional Normal/RoughnessMetalness; MetalnessMap only when needed |
| 6. Wire | Rojo `ReplicatedStorage.Assets` **or** Studio-only folder | Lua clones by name; never hardcode fake IDs |
| 7. QA | Device + mid Android | LOD0 only near camera; LOD2 for far parallax |

### Naming

```
FM_<Role>_<Subject>_<Variant>_LOD<0-2>
```

Roles: `Enemy`, `NPC`, `Prop`, `Persona`, `VFX`, `UI`.

### Animation export

- R15-compatible Humanoid rig **or** custom Motor6D skeleton matching `EnemyFactory` bone names.
- Export actions: `Idle`, `Run`, `Jump`, `Dodge`, `Attack1`, `Attack2`, `Attack3`, `Skill`, `Swap`.
- Upload via Animation Editor → paste real AnimationId into `AnimController.AnimationIds` (see §5). Empty / missing IDs → procedural fallback (already implemented).

---

## 2. Swapping Part kits for MeshParts

**Today:** `EnemyFactory` / `WorldBuilder` build Part soup and set `model:SetAttribute("ArtKit", "InEngine_v2")`.

**When meshes exist:**

1. Drop MeshPart models under `ReplicatedStorage.Assets.Meshes` (Studio) named exactly like subject (`BeachCrab`, `CrabKingBoss`, `CaptainSteve`, …).
2. At build time: `local kit = Assets.Meshes:FindFirstChild(def.id)`; if present, clone + scale to `def.size`, set `ArtKit = "Mesh_v1"`, skip Part builder.
3. Keep Part builder as permanent fallback for Studio-less CI / Rojo smoke.

**Do not** delete Part kits until Mesh_v1 covers all slice enemies + hub NPC.

---

## 3. In-engine materials (SurfaceAppearance-like)

Roblox `SurfaceAppearance` needs uploaded textures. Until then we approximate with **Material + Color palettes**:

| Feel | Material | Typical use |
|------|----------|-------------|
| Sand | `Sand` / `SmoothPlastic` | Beach crabs, ground |
| Sludge | `Mud` | Oil gator, Spillfather chassis |
| Hazmat / metal | `Metal` | Drive-Thru collar, boss mech |
| Neon gas | `Neon` | Crowns, weak points, flame |
| Glass / wet | `Glass` / `ForceField` | Slushie, eyes, spill sheen |
| Soft body | `Plastic` / `SmoothPlastic` | Steve feathers, cooler |

Particle **ColorSequence** decals stand in for painted markings (mustard stripe sparks, oil drip, sand dust).

---

## 4. Hero kit targets (Phase 2 cast)

| Subject | Builder | In-engine upgrade |
|---------|---------|-------------------|
| Florida Man (player) | Default R15 + persona tint | `BodyColors` + `Highlight` from active persona |
| Captain Steve | `WorldBuilder._BuildHub` | Pelican SpecialMesh spheres/wedges, neon beak, pouf particles |
| Beach Crab | `EnemyFactory.buildCrab` | Sand carapace, Ball dome SpecialMesh, Neon pupils |
| Crab King | `buildCrab` miniboss branch | Tide crown wedges + PointLight |
| Drive-Thru Gator | `buildGator` | Mud body, Metal radio collar, Neon GULFGULP |
| Spillfather | `buildBoss` | Mud chassis, Metal claws, oil ColorSequence drip |
| Hub bonfire | `_BuildHub` | Cylinder logs, layered flame particles, warm PointLight |

---

## 5. Animation layer

Module: `src/client/Controllers/AnimController.lua`

1. If `AnimController.AnimationIds[personaId][clip]` is a non-empty `rbxassetid://…`, `Humanoid:LoadAnimation` + play/override default Animate.
2. Else **procedural fallback:** HRP squash-stretch + Motor6D pose offsets (RightUpperArm / LeftUpperArm when present).
3. Starter poses authored in code: **BeachBurnout** (wide slap) and **CrabKing** (sideways pinch lean).

**Registry (fill when uploaded):**

```lua
AnimController.AnimationIds = {
  BeachBurnout = { Idle = "", Run = "", Jump = "", Attack1 = "", Dodge = "", Skill = "" },
  CrabKing = { Idle = "", Run = "", Jump = "", Attack1 = "", Dodge = "", Skill = "" },
}
```

---

## 6. VFX kit

`src/client/Controllers/VFX.lua` — `SwingSlash(hrp, facing, combo, vfxKind)`

Wired `weapon.vfx` strings (catalog must not lie for these):

| `vfx` | Arc |
|-------|-----|
| `punch` | Short neon fist burst |
| `slap` | Wide horizontal flip-flop arc |
| `dart` | Thin thrown streak + tip spark |
| `firework` | Multicolor sparkler trail |

Other catalog `vfx` values fall back to generic slash until Phase 3 polish.

Server sets `character:SetAttribute("WeaponVfx", weapon.vfx)` so client InputController can pass the kind without inventing IDs.

---

## 7. UI image pack fallback

- Persona HUD icons: **circular** colored frames (`UICorner` scale 1) + accent glyph; rarity stroke colors unchanged.
- Optional `ImageLabel` fill: `rbxasset://textures/ui/GuiImagePlaceholder.png` only as frame texture — never fake marketplace icons.
- Real PNG pack lands in `assets/ui/` then Studio upload → replace ImageLabel `Image` with real IDs in a follow-up.

---

## 8. Thumbnail / loading screen spec

| Asset | Size | Copy / notes |
|-------|------|----------------|
| Experience icon | **512×512** | Bonfire silhouette + “FLORIDA MAN” wordmark; high contrast |
| Thumbnails (up to 10) | **1920×1080** | Hub bonfire, Crab King pinch, Drive-Thru Gator collar, Spillfather arena |
| Wide thumbnail | **1920×1080** | Same as primary trailer still |
| Loading / splash | in-game ScreenGui | Title **FLORIDA MAN**, subtitle *Bonfire to Boardwalk*, warm orange on night blue — **no marketplace upload required** |

In-game: `src/client/UI/LoadingGui.lua` (fades after client ready). Marketplace Creative Hub upload is a **publish** step, not a Lua ID invent.

---

## 9. LOD / part-count budgets (slice stages)

Budgets are **targets** for mid-range Android (~Adreno 6xx). Measure in Studio MicroProfiler before claiming PASS.

| Stage | Index | Enemy peak | Soft part budget (active) | Notes |
|-------|------:|------------|---------------------------:|-------|
| Hub | 0 | 0 hostiles | ≤ 180 parts | Steve + bonfire + décor |
| Daytona Hangover | 1 | ~8 + Crab King | ≤ 450 | Teach telegraphs; sand particles low rate |
| Boardwalk Chaos | 2 | ~10 | ≤ 550 | Carts/tourists denser |
| Gas Station | 3 | ~12 | ≤ 650 | MidGate + oil props |

| LOD | Distance | Mesh tris (future) | Part kit rule |
|-----|----------|--------------------:|---------------|
| LOD0 | &lt; 40 studs | ≤ 8k | Full kit |
| LOD1 | 40–90 | ≤ 3k | Drop eye pupils / drip / secondary claws |
| LOD2 | &gt; 90 | ≤ 800 / billboard | Root + 1 silhouette part |

**VFX:** ≤ 3 ParticleEmitters emitting per player action; death poofs Debris ≤ 0.6s.

---

## 10. Asset ID registry (empty until real)

| Key | Type | ID | Notes |
|-----|------|----|-------|
| — | — | — | *No Mesh/Animation IDs checked in. Add rows only after Studio upload.* |

---

## 11. Checklist before claiming Mesh_v1 done

- [ ] ≥6 slice characters use real MeshParts  
- [ ] BeachBurnout Attack1 AnimationId plays  
- [ ] SurfaceAppearance sand/sludge on ground or hero props  
- [ ] Budgets measured on mid Android  
- [ ] `./scripts/check_invariants.sh` still green  
