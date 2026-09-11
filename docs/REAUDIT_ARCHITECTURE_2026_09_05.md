# Architecture and responsibility re-audit — 2026-09-05

This is an independent, source-based pass over the live working checkout, bounded to architecture, ownership, public catalogs/presentation, profile/provider boundaries, and release/QA tooling. No engine, build, test suite, provider call, network access, or separate security scan was run by this reviewer. No source files were edited by this reviewer. The root audit owns integration, test evidence, and the existing security scan. Concurrent edits mean this document is review coverage, not certification of an immutable release artifact.

No AGENTS.md or SECURITY.md was found in the repository or the inspected ancestor directories. Earlier audit findings were not used as proof about current source.

## Result

No additional reachable client-to-profile, client-to-entitlement, or client-to-server-code authority violation was found in the fully reviewed files. This does not certify the unreviewed implementation bodies listed under coverage.

A concrete stale-success report defect was found in the validator and sent to the root reviewer. The root corrected it during this pass; the changed failure handling was reread. A subsequent same-directory QA output collision was identified and corrected before finalization. The corrections are source-verified here; execution evidence belongs to the root audit.

The new build identity and stage smoke maintain a useful separation: the main source manifest identifies the game source, the QA helper has its own hash, and service smoke explicitly disclaims player traversal and campaign acceptance. The default project does not ship the QA helper.

## Fresh threat model

Protected assets are the admitted player's profile, permanent unlocks and Sunburn balance, run inventory and reward/completion ledger, the shared world, character admission, server availability, silence/presentation policy, and the provenance of release evidence.

The untrusted game actor is a connected client. It can inspect all ReplicatedStorage catalogs and snapshots, send declared remotes directly and repeatedly with malformed or replayed payloads, spoof local UI state, and manipulate its network-owned character physics. Knowledge of a catalog ID, generation number, or public session identifier is not authorization.

Roblox supplies Player identity and server-only DataStore/Analytics provider APIs. Provider results can be absent, malformed, newer-schema, stale, conflicting, or unavailable, so they remain a validation/failure boundary. Trusted maintainers control source, optional imported templates, the local toolchain and publishing configuration; this pass does not assume a malicious publisher can be constrained by game code.

| Boundary | Observed control and residual limit |
|---|---|
| Client → session/world | GameService requires SessionService.IsOwner before command budgets are allocated; InitPlayer acquires the sole owner before profile/world initialization. See GameService.lua:46, :152 and SessionService.lua:8. Deployed MaxPlayers is still an external setting. |
| Client → run/economy | Remotes carry intent; RunContext's private table owns accepted state. ItemGrantRules validates current phase/generation, offer membership, ownership, slots, request identity, sequence, and affordability. See RunContext.lua:28, ItemGrantRules.lua:8, :33, :55, :66 and HubService.lua:91. |
| Client physics → spatial decisions | GameService's spatialAction calls MovementAuthority.Validate before attacks, skills, swaps and world interactions; RunContext.TeleportPlayer delegates trusted relocations to MovementAuthority.Reset. See GameService.lua:106 and RunContext.lua:222. The MovementAuthority implementation is reviewed by the separate movement pass, not claimed audited here. |
| Runtime profile → persistent storage | MetaService is the sole DataStore binding. ProfileAdapter validates data and leases inside UpdateAsync, requires expected revisions, and handles retries of an immutable write. ProfileQueue coalesces later mutations without changing a pending operation. See MetaService.lua:33, ProfileAdapter.lua:7, :44 and ProfileQueue.lua:13. |
| Server → client presentation | PushState sends a selected public snapshot and status, not a provider handle, profile write key or lease owner. Local equipment and UI receive accepted data and send requests. See RunContext.lua:98, EquipmentController.lua:14 and CaptainSteveUI.lua:15. |
| Catalog/template → game | Shared catalogs are public definitions; local changes do not change the server VM. ArtAssets rejects executable containers, several runtime controllers, Sound/AudioPlayer and excessive geometry before cloning; collision/query/touch flags are normalized. See ArtAssets.lua:136, :163. The current project maps empty asset folders; imported-asset/permission acceptance remains separate. |
| Server → analytics | AnalyticsAdapter owns provider enum fields and drains a bounded queue. Client device cohort is an allowlisted, non-authoritative dimension. See AnalyticsAdapter.lua:11, :18, TelemetryRules.lua:4 and GameService.lua:390. No gameplay permission depends on telemetry. |
| Workspace → release evidence | Build identity is a SHA-256 over an explicit source manifest, embedded only in a derived project. A QA report also binds the helper and package hash. The report is local evidence, not a signature, publication authority, or proof of gameplay. See build_identity.py:7, :18 and build_studio_audit.py:65. |

There is no MarketplaceService purchase/receipt or paid entitlement implementation in the mapped source search. Current entitlements are game-earned personas/weapons and server-side shop mutations. No player-controlled arbitrary require, loadstring, asset download, HTTP request, or provider credential path was found in the mapped-source search. Search coverage alone is not counted as full-file review.

## Ownership matrix

| Responsibility | Owner / source evidence | Consumers and limits |
|---|---|---|
| Admission and callback lifetime | SessionService.lua:8, :25, :36, :55 | GameService owns join/removal ordering. Generations cancel obsolete delayed run work; named connections replace previous character listeners. |
| Accepted run truth | RunContext.lua:28, :46, :64, :165 | Gameplay services receive the server table. Client PresentationState is a local projection and modal state. |
| Phase, waves, rescue and completion | StageFlowService.lua:58, :100, :252, :286, :340; ProgressionRules.lua:17, :29 | Completion requires waves, room, hostile/miniboss/boss and rescue conditions, then a once-per-stage claim. FinishRun requires the final stage and committed shared reward transaction. |
| Shop and permanent unlock intent | HubService.lua:91; ItemGrantRules.lua:8, :66; RunContext.lua:242 | Shared catalog entries supply descriptions/definitions, not entitlement checks. Upgrades/smashing require a writable profile; equip still permits a temporary session loadout. |
| Profile schema and safe defaults | ProfileRules.lua:46, :56 | Known catalogs bound IDs, selected loadout and settings; unknown fields and retired audio settings are discarded. |
| Persistence and provider lease | MetaService.lua:33, :112, :206, :230, :263; ProfileAdapter.lua:6; ProfileQueue.lua:13 | Only Load and the provider worker yield into storage. Failed loads stay non-writable; transient runtime progression can still continue. Public status includes revisions but not the lease capability. |
| Derived stats and character projection | RunStats.lua:10; BuildRules.lua:5; CharacterStatePublisher.lua:12, :57 | Character attributes/appearance reflect accepted server state; the client held weapon has no damage or collision authority. |
| Transport | Remotes.lua:5, :38, :56; GameService.lua:251 | One declared event set and server composition point. Ingress budgets and rejected-reply budgets are distinct. |
| Local UI and dialogue | client/init.client.lua:66; UiKit.lua:65; CaptainSteveUI.lua:15; Story.lua:9 | Server snapshots drive permissions; client panels send intent. Story text contains no provider/private-profile payload. Dialogue is text; gameplay readability is a device test. |
| Silence | RbxCharacterSounds.client.lua:1; SilenceController.lua:6, :25; default.project.json:33 | Reserved-name script replaces character sound creation; local Sound/AudioPlayer suppression covers later descendants. Platform voice configuration and other audio APIs are not proven disabled by this source review. |
| Diagnostics and bounded memory | RuntimeMetrics.lua:11, :26, :39; MetricsWindow.lua:5; AnalyticsAdapter.lua:11 | Rolling timings hold 120 samples; telemetry queue holds 64 entries; command journal holds 64 results; RunContext.Say holds 16 deferred lines. These are bounds for reviewed containers, not a measured whole-game soak result. |
| Build, QA and release control | validate.py:43; build_identity.py:18; build_studio_audit.py:34; StudioAudit.luau:22, :121 | Builder/validator use a shared lock, sequential tool processes and hashes. QA mutation requires Studio server, PlaceId 0, admitted owner, loaded non-writable profile and living ready character. Neither builder publishes. |

## Defects identified and correction review

1. **P2 — Failed validation rerun could leave a previous passing report.** Originally scripts/validate.py:54, :57, :67 and :89 wrote the report only after all fallible work completed, with finally limited to releasing the lock. A timeout, missing tool or subprocess/IO failure in a reused output directory left its old passed:true report and package in place. The QA builder's original baseline gate accepted the old report when source hashes still matched. This was reachable through the ordinary --output workflow without an attacker. The root now initializes a false report before fallible validation work and writes error/final status in finally (current validate.py:54, :64, :95, :100). The QA builder also invalidates its previous report before validating its input (build_studio_audit.py:65). Existing package files may remain, so consumers must use the current report and matching package hash; mere file existence is not success. **Source correction reviewed; failure-injection execution not performed by this reviewer.**

2. **P2 — QA output could overwrite its own baseline report.** During the fail-closed correction, setting --output to the baseline validation directory would write the initial false QA report to the very path about to be read as the baseline. This would destroy usable validation evidence and reject itself. The root added a resolved path equality guard before output creation/report mutation at build_studio_audit.py:43. **Source correction reviewed; execution not performed by this reviewer.**

3. **Historical QA evidence claims were stale.** The earlier qa/README.md claimed a current package hash, a 93-check baseline and no runtime invocation despite the new helper/source. The root replaced those claims with an explicit pointer to the current re-audit, historical artifact labels, the separate QA hash, and a correct description of RunStageSmoke. The revised file was fully reread. This documentation mismatch is corrected, not an open runtime defect.

No additional unresolved concrete released-code defect was established within this bounded pass.

## QA/package conclusions and remaining evidence

RunStageSmoke loads a fresh run for each stage, uses explicit authorized server relocations and lethal test damage, then invokes real kill/rescue/finish services. It checks supported spawns, stage readiness, rescue demand, refusal before required waves, reward commitment, repeated completion and a final hub reset (StudioAudit.luau:121). Its mutation helper has no remote exposure and is absent from default.project.json. Requiring the QA module alone does not invoke the smoke.

This validates a useful service path when executed, but cannot certify regular input, movement-authority acceptance of real client motion, traverseable geometry, combat difficulty, all loadouts, both finale objective orders, or a continuous twenty-stage campaign. Profile writes, shutdown persistence, analytics delivery, target device performance, imported animation permissions and platform voice settings require their own controlled evidence. No such execution is claimed in this document.

The main source manifest currently covers all source .lua files plus tests and selected build inputs. QA intentionally has a separate hash. Any future mapped non-Lua model/metadata/config files must be incorporated into provenance before relying on the same identity contract; none were present in the inspected src inventory.

## Exact full-file review coverage

The following 39 runtime source files were fully read, including overlapping files needed to trace boundaries. Counts are deduplicated. No test file is included in this count.

```text
src/character/RbxCharacterSounds.client.lua
src/client/Controllers/EquipmentController.lua
src/client/Controllers/PresentationState.lua
src/client/Controllers/SilenceController.lua
src/client/UI/CaptainSteveUI.lua
src/client/UI/UiKit.lua
src/client/init.client.lua
src/server/AnalyticsAdapter.lua
src/server/CharacterStatePublisher.lua
src/server/FunnelService.lua
src/server/GameService.lua
src/server/HubService.lua
src/server/ItemGrantRules.lua
src/server/MetaService.lua
src/server/ProfileAdapter.lua
src/server/ProfileQueue.lua
src/server/ProfileRules.lua
src/server/RunContext.lua
src/server/RunStats.lua
src/server/RuntimeMetrics.lua
src/server/SessionService.lua
src/server/StageFlowService.lua
src/server/init.server.lua
src/shared/ArtAssets.lua
src/shared/BuildRules.lua
src/shared/Enemies.lua
src/shared/Items.lua
src/shared/MetricsWindow.lua
src/shared/Movesets.lua
src/shared/Personas.lua
src/shared/ProgressionCatalog.lua
src/shared/ProgressionRules.lua
src/shared/Remotes.lua
src/shared/Settings.lua
src/shared/Stages.lua
src/shared/Story.lua
src/shared/TelemetryRules.lua
src/shared/Types.lua
src/shared/Weapons.lua
```

The following 15 project, tooling, QA or policy/documentation files were fully read. They are not additional runtime-source coverage.

```text
.github/workflows/validate.yml
default.project.json
docs/PUBLISH_CHECKLIST.md
docs/RELEASE_ACCEPTANCE.md
qa/README.md
qa/StudioAudit.luau
rokit.toml
scripts/bootstrap-tools.ps1
scripts/build_identity.py
scripts/build_studio_audit.py
scripts/check_contracts.py
scripts/check_invariants.sh
scripts/studio_mcp.py
scripts/toolchain.json
scripts/validate.py
```

Partial/mapped-only: EnemyFactory.lua was inspected at template import, attribute assignment, build and animation/cleanup boundaries but its entire 1,367-line body was not fully read; it is not counted above. Other files returned by rg, referenced by imports, or owned by movement/client/gameplay reviewers are not counted as audited here. No prior audit report, generated source map, test pass or package listing was substituted for source review.
