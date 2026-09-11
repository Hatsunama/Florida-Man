# Release acceptance for the repaired game

This is the current release gate. Earlier phase audits, scorecards and plans describe historical revisions; they cannot authorize this build.

The source validator runs compiler, Roblox-aware type analysis, meaningful rule tests, contract checks and Rojo packaging sequentially. Every report records source hashes and rejects files changed during validation. Packaging does not certify gameplay, assets, cloud data or devices.

| Gate | Required evidence | Current evidence owner |
|---|---|---|
| Source compilation | All mapped source and test files compile | `scripts/validate.py` |
| Roblox types/contracts | No type errors; no missing remotes/service methods/audio pipeline | `scripts/validate.py` |
| Domain behavior | Failure injection, exact offers, transactions, finale order, geometry, movement, layout, telemetry | `tests/*.test.luau` |
| Engine boot | Fresh local place, server/client ready, live character, camera, hub, first stage; no errors | Studio execution record |
| Full campaign | All 20 stages traversed with objectives and rewards; boss-first/turtle-first and duplicate finish | Studio campaign record |
| Save durability | Controlled test universe rejoin/migration, failed reads, overlapping leases, response loss and shutdown | Live test profile record; never production rewrite |
| Session model | Second simultaneous join rejected before world/profile initialization; deployed MaxPlayers1 | Studio test plus Creator Hub verification |
| Controls/UI | Keyboard, touch and controller essential actions, focus, portrait/landscape, Unicode small popups | Device/screenshots record |
| Silence | Fresh/old profile, respawn, default character, all verbs/stages/credits; voice disabled in experience configuration | Studio/device plus Creator Hub record |
| Assets | Procedural fallbacks, partial/denied animation clips, imported-model validation, actual permissions | Asset/rig test record |
| Resources | Long campaign/repeated deaths/runs: stable connections, tasks, instances, heap and frame times | Device profiler/soak record |
| Analytics | Provider retains stage/outcome/cohort; successes, timeouts and abandons included | Controlled provider delivery record |
| Build and rollback | Exact package hash, revision plus source hashes, verified deployment settings and previous artifact | Final release record |

Do not publish while a release-blocking row lacks evidence. Do not substitute a generated checklist, compiler pass, screenshot mockup, or an AI playability assertion for an unexecuted check.

Current decisions use the [consolidated re-audit](REAUDIT_2026_09_05.md) and [structured runtime records](reaudit-evidence-2026-09-05/runtime-results.json). Latest [main09](../artifacts/reaudit-build-09/report.json) passed 78 runtime files, 15 behavioral suites and 112 checks; [QA09](../artifacts/reaudit-studio-09/report.json) passed six separate checks. Their identity is d5e040a6ef142…; full package hashes are in the ledger. Neither 09 artifact has engine acceptance. Latest actual runtime source remains08: native Hub Tab, Input.Intent walk/jump, native NPC E without relocation and bounded client silence. Earlier sessions established bonfire E, accepted dodge, confirmed Return and numerical native Space rise/return. These scoped successes do not certify native held movement keys, Active combat or the full campaign.

Acceptance is still incomplete. O hit Studio zoomOutAction in 05; native Tab passed only its 08 Hub case. The 08 client read exposed startup zero-viewport pagination permanently fragmenting dialogue, such as “retry.” at 376px. Main09 retains full messages, delays pagination until valid actual layout and preserves grapheme offsets; its production pure pagination suite passed, but actual complete-conversation reading is unexecuted. Earlier QA06 stage smoke returned 20 records but failed stage-owned support and its aggregate log was truncated. A collider outside GameWorld can explain that assertion without proving absent physical floor. Main08 bootstrap cleanup passed source validation; stage/lifecycle/Active-combat smoke was not run on 08 because commit headroom fell below the host threshold. No campaign/progression pass is claimed.

The main05 server scan inspected 2,155 nodes; main08 client inspected 2,342. Both reported zero audio findings and no truncation. Their scope does not establish all future actions/stages or experience voice configuration. Security [source coverage](REAUDIT_SECURITY_COVERAGE_2026_09_05.md) is sealed at 07:00:27 UTC: 138 reviewed current paths, including 112 authoritative files (78 runtime), 3 ancillary source/guidance files, 22 retired legacy scripts and their README. No additional reportable security finding was established within that reviewed scope; the 2,149 exclusions are explicit, with no unreviewed-authoritative or unclassified remainder. This is source review, not engine/provider/deployment acceptance; no final release or mission-completion claim is supported.

Use the [isolated QA server bridge](../qa/README.md) within the host's resource policy. Direct Command Bar require returned a session guard refusal in this environment; the existing server-only BindableFunction bridge succeeded. Its build and service smoke results are separate from normal traversal, combat balance, device, provider and campaign evidence. The consolidated ledger owns later updates so historical package success is never attributed to unvalidated source edits.

[Three final tooling failure cases](../artifacts/reaudit-tooling-failure-final/checks.json) passed: absent tools or QA baseline invalidate stale success and release locks; QA output aliasing refuses with the exact guard and leaves the main09 report hash unchanged. An earlier harness omission of --tools-dir is preserved separately and is not treated as a source defect or guard proof. This closes those tooling regressions, not any engine gate.

`RuntimeMetrics.GetLatest()` exposes bounded developer samples (120 simulation/server-heartbeat timings, five-second snapshots, workspace instance count, active/pending enemies, hazards, scoped tasks/connections, profile workers/queues and analytics counters). These are server diagnostics, not measured client FPS. Rejected ingress response traffic is bounded separately from accepted command budgets.

## Resource policy

The development host has about 6.83 GiB usable physical RAM. Heavy tools/builds remain sequential; no pagefile settings or unrelated processes are changed. Use one Studio instance and close only the instance opened for this task. Stop additional heavy work below 512 MiB free physical memory or 2 GiB commit headroom. During QA08, headroom repeatedly reached 1.45–1.61 GiB; stage/lifecycle/Active-combat smoke was not executed. The root closed its own Studio and recovered about 5.0 GiB commit headroom/1.9 GiB free physical memory. A single play session consumed roughly 3.5 GiB commit headroom, so the recovered idle value does not establish sustainable capacity for another heavy run. Resume those gates on a host with enough sustained headroom; retain the explicit unexecuted status until evidence exists. These operating thresholds are not target-device performance claims.

## Required device campaign cases

Use the detailed W10 matrix in [the implementation plan](PLAN_2026_09_04_IMPROVEMENTS.md). At minimum: smallest supported viewport, moving/standing/high-X camera, quick reverse-skill input, held/released jump, grounded safe fall, dash into locked door from each side, slowest legal combo, projectiles against shortest/tallest enemies, interrupted/dead windups, full-inventory replacement, every selected persona, persistent upgrade and finale weapon, failed-save status, fast story transitions, text reveal/dismiss, boss-first/turtle-first finale, repeated runs and player replacement.

## Provider and tool references

- [Roblox analytics custom fields](https://create.roblox.com/docs/production/analytics/custom-fields): only three defined string dimensions are sent; unique session IDs are deliberately excluded from these low-cardinality breakdowns.
- [Roblox Studio MCP](https://github.com/Roblox/creator-docs/blob/main/content/en-us/studio/mcp.md): `scripts/studio_mcp.py` talks only to the preinstalled official binary and never enables permissions or publishes.
- [Luau LSP](https://github.com/JohnnyMorganz/luau-lsp): the pinned analyzer uses a Rojo sourcemap and matching Roblox definitions. `scripts/toolchain.json` records URLs, revisions and checksums.
