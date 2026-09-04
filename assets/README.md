# Florida Man — Art Assets

**Status (Phase 2):** Pipeline + folder convention only. **No authored MeshParts / FBX / uploaded AnimationIds ship in this repo yet.**

Do **not** invent `rbxassetid://` Mesh or Animation IDs. Placeholders stay empty until Studio upload produces real IDs; then wire them in `docs/ART_PIPELINE.md` § Asset ID registry.

## Folder convention

| Path | Purpose |
|------|---------|
| `assets/meshes/` | Source FBX / Blend exports before Rojo/Studio import (git-LFS optional later) |
| `assets/animations/` | Source `.fbx` / `.anim` exports; Studio Animation Editor dumps |
| `assets/textures/` | Albedo / normal / roughness for SurfaceAppearance (when available) |
| `assets/ui/` | PNG icons (personas, rarity frames, masthead, draft cards) |
| `assets/templates/` | Blender starter kits / naming checklists |

## Naming

```
FM_<Role>_<Subject>_<Variant>_LOD<0-2>
```

Examples: `FM_Enemy_BeachCrab_A_LOD0`, `FM_NPC_CaptainSteve_Base_LOD1`, `FM_Persona_BeachBurnout_Attack01`.

## Swap path (Parts → MeshParts)

1. Author in Blender per `docs/ART_PIPELINE.md`.
2. Import FBX in Studio → MeshParts.
3. Tag model with `ArtKit = "Mesh_v1"` attribute.
4. In `EnemyFactory` / `WorldBuilder`, prefer MeshPart clone when `ReplicatedStorage.Assets.Meshes:<Name>` exists; else keep in-engine Part kit (`ArtKit = "InEngine_v2"`).

## What lives in Lua today

In-engine hero kits use **Parts + SpecialMesh (built-in MeshTypes only) + Materials** (Sand/Mud/Metal/Neon/Glass/Plastic). See `docs/ART_PIPELINE.md`.
