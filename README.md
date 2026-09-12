# Florida Man

A silent Roblox 2.5D side-scrolling roguelite: recover the stolen Florida Dew, follow GulfGulp's wildlife experiments, rescue the turtles, and confront the Spillfather. The campaign has 20 stages plus the bonfire hub, eight personas, 28 weapons and 28 items, presented with procedural models and small text popups.

## Current status

The latest engine observations are limited to main08: Hub Tab, movement/jump through real Input.Intent, NPC E after approach, and a bounded client audio scan. A separate main05 native Space trace measured a 7.323493-stud rise and return with no reset. The [consolidated audit](docs/REAUDIT_2026_09_05.md) ties each result to its build and limits. Main09 passed static packaging and pure rules, but no main09 engine result exists. This branch adds further static repairs: E now shows Steve's popup conversation while Tab opens his shop, cooldown snapshots come only from server combat authority, dodges retain their accepted direction, transient menus clean up across lifecycle changes, audio policy is centralized, and two archive-backed recovery items are server-authoritative. These repairs still require a Studio playthrough.

The full mission remains open. QA08 exposed startup conversation fragmentation. Main09 now retains whole messages, paginates only with valid layout and preserves grapheme offsets; the new production pagination suite passed, but complete-conversation engine reading remains open. O remains a Studio shortcut conflict, although native Tab worked in the 08 Hub. Stage/lifecycle/Active-combat tests were not run on 08 because commit headroom fell below the 2 GiB threshold; the task's Studio was closed. The earlier stage-support smoke failed an ownership assertion with truncated output and proves no campaign pass. Server/client audio scans were clear only within their inspected scopes; all verbs/stages and experience voice configuration remain separate gates. Use the [current ledger](docs/REAUDIT_2026_09_05.md), [release acceptance](docs/RELEASE_ACCEPTANCE.md) and [isolated QA instructions](qa/README.md). Historical scorecards do not certify current gameplay. Do not publish until current acceptance gates have evidence.

## Build and validate

Requirements: Python 3.11+, Windows, Roblox Studio for engine tests. Pinned tools are checksum verified outside the repository; no package manager or background development server is required.

```powershell
./scripts/bootstrap-tools.ps1
python scripts/validate.py
```

The validator compiles every mapped source, checks Roblox types and explicit contracts, executes pure rule/failure tests, and only then packages `artifacts/validation/FloridaMan.rbxlx`. It rejects concurrent changes and records the commit, source hashes, tool versions and build hash. All subprocesses run sequentially. `scripts/check_invariants.sh` is a narrow structural check only.

Open the resulting place in Studio. The old root `FloridaMan.rbxlx` is an ignored comparison artifact and is not automatically overwritten. Rojo 7.7.0 can also serve this project if desired.

## Play and progression

- One admitted player owns each server world. Set deployed MaxPlayers to 1 as well; server admission enforces the same boundary.
- Move with A/D or arrows, left stick, or touch arrows. Jump with Space, controller A, or the touch button; hold/release controls height.
- Attack, skill, dodge and swap share one input-intent path across devices. Keyboard defaults: click/J, K, Shift and Q. Controller hints and touch buttons expose the equivalent actions.
- Interact beside the bonfire, Captain Steve or a turtle. Conversation stays in small nonmodal text. Necessary story facts remain available in Notes.
- Choose up to two distinct unlocked personas in the hub. Earned personas, rarity upgrades, selected loadouts, Sunburn and weapon unlocks persist. Items last for one run.
- Item capacity starts at 3 and grows to 4/5/6 at stages 6/11/16. Every inscription needs three distinct pieces. Full inventories can replace an item or skip a reward.
- Every required encounter and rescue must finish before an exit opens. The finale requires both boss defeat and all final turtles; rewards commit once. The Finale Rocket remains available for later runs.
- Options control presentation: text speed/size, reduced motion, flashes and telegraph accessibility. There are no audio settings or playback pipeline.

## Architecture

`GameService` composes services and validates command ingress. `SessionService` owns single-player admission and generation-scoped callbacks. `RunContext` stores accepted run state and publishes snapshots, delegating stats to pure `BuildRules` through `RunStats` and character projection to `CharacterStatePublisher`. `StageFlowService` owns encounter progression and idempotent rewards. Profile schema/queue rules are separated from the Roblox storage adapter. Server combat owns timing/hits/results; clients own input prediction, camera, animation, visuals and UI. World layout/hazard definitions are separate from Part construction.

## Deterministic content analysis

```powershell
python scripts/export_catalog.py --luau "$env:LOCALAPPDATA/FloridaMan/toolchain/luau-0.737/luau.exe"
```

The export evaluates current catalogs and all legal item combinations. Attack-cycle DPS is an uninterrupted upper bound, not an observed encounter result. Enemy HP scales by `1 + 0.09 × stageIndex`; damage by `1 + 0.075 × stageIndex`, with separate miniboss factors. Actual difficulty, frame time, avatar assets and live persistence require the engine/device acceptance pass.
