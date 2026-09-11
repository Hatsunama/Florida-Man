# Source implementation evidence

The files in this folder are a frozen copy of the final source validator and behavioral outputs. `report.json` contains exact source/test/configuration hashes, tool versions, all 93 check results, baseline revision and package hash. The working-tree implementation is uncommitted, so the commit ID alone does not identify the resulting game.

- All 71 source and 9 test files compile.
- Roblox-aware type analysis has no source diagnostics. Its automatic-file-watch warning is expected in the one-shot command.
- Nine behavioral suites pass. They execute production pure rules and controllable provider adapters; they do not emulate a Roblox game engine.
- `contracts.json` is empty. Narrow audio/remote/service-method/VFX-mechanics policies pass.
- Rojo packages only after preceding checks pass and the report verifies stable sources.
- `catalog-summary.json` describes the separate executable catalog/layout/stat analysis. Full regenerable data is in `artifacts/catalog`.
- `engine-attempt.json` records the aborted resource-limited Studio attempt. No game frame, screenshot, real-device test or live-provider acceptance is inferred.

Normal package: `artifacts/validation-final-2/FloridaMan.rbxlx`; SHA-256 `6ceceb763bc1026b0ec81c44e6def1d88bb68b97be5e379b836fc5625e61e692`.

`studio-audit-report.json` records four further passing checks for the isolated QA module/package, including a guard that the normal project was not modified. Its helpers were not executed in Roblox.

See [implementation result](../IMPLEMENTATION_RESULT.md) for disposition of all 47 original findings and 18 additional repairs, ownership review, and the ordered remaining acceptance work. The prior audit evidence folder remains historical and unchanged.
