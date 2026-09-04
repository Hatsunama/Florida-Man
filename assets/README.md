# Florida Man — Art Assets

**Status (N7):** Pipeline + empty Rojo `ReplicatedStorage.Assets` scaffolding + folder convention. **No authored MeshParts / FBX / uploaded AnimationIds ship in this repo yet.**

Do **not** invent `rbxassetid://` Mesh or Animation IDs. Placeholders stay empty until Studio upload produces real IDs; then wire them in `src/shared/ArtAssets.lua` and `docs/ART_PIPELINE.md` §10.

## Folder convention

| Path | Purpose |
|------|---------|
| `assets/meshes/` | Source FBX / Blend exports before Studio import |
| `assets/animations/` | Source `.fbx` / `.anim` exports |
| `assets/textures/` | Albedo / normal / roughness for SurfaceAppearance |
| `assets/ui/` | PNG icons |
| `assets/templates/` | Naming checklists |

## Runtime swap (Parts → MeshParts)

1. Author in Blender per `docs/ART_PIPELINE.md`.
2. Import FBX in Studio → MeshParts under `ReplicatedStorage.Assets.Meshes.<SubjectName>`.
3. Tag is automatic: `ArtAssets.TryCloneMeshModel` sets `ArtKit = "Mesh_v1"`.
4. Else Part kit (`ArtKit = "InEngine_v3"`) from `EnemyFactory` / `WorldBuilder`.

## What lives in Lua today

In-engine hero kits use **Parts + SpecialMesh (built-in MeshTypes only) + Materials**. Validation: `ArtAssets.IsValidAssetId`.
