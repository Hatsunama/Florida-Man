# Blender / FBX naming checklist

- [ ] File: `FM_<Role>_<Subject>_<Variant>_LOD0.fbx`
- [ ] Root empty / armature at origin (feet)
- [ ] Apply scale (1,1,1) before export
- [ ] Imported game model faces +X, Up Y (match `ArtAssets` / `EnemyFactory`; convert authoring axes on export)
- [ ] No invented Roblox asset IDs in commit messages
- [ ] After Studio import: paste real IDs into `docs/ART_PIPELINE.md` §10 only
