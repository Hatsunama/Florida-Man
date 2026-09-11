# Security Review: Florida-Man

## Scope

Security component of the comprehensive Roblox game audit: client remote authorization, session/resource ownership, physics-to-combat trust, profile storage and provider boundaries.

- Scan mode: repository
- Target kind: git_revision
- Target ID: target_sha256_6327efc8ab390fbbe6f636f58a2df1a8e9fbbe5986991a6bab021a41371e0153
- Revision: 1bff8c516fd0dfed08f991e0c23c008c665f707d
- Inventory strategy: repository
- Included paths: .
- Excluded paths: none
- Runtime or test status: Not executed in Roblox Studio; current source blocked by HazardService syntax error.
- Artifacts reviewed: src/server, src/shared, src/client, default.project.json

Limitations and exclusions:
- Formal security baseline fully read21 of48Lua sources plus project mapping; other files received product/architecture review, not a full independent security pass.
- No cloud fault injection, multi-client runtime, physics exploit, or deployment admission verification.
- TAC status unavailable: security access connector not connected.

### Scan Summary

| Field | Value |
| --- | --- |
| Scan outcome | completed |
| Reportable findings | 3 |
| Severity mix | medium: 3 |
| Confidence mix | high: 2, medium: 1 |
| Coverage | partial |
| Validation mode | static source review with independent baseline and parent validation |

Canonical artifacts: `scan-manifest.json`, `findings.json`, and `coverage.json`. This report is a deterministic projection of those files.

## Threat Model

Florida Man is a Roblox Luau 2.5D roguelite. Rojo maps src/shared to ReplicatedStorage.Shared, src/server to ServerScriptService.Server, and src/client to StarterPlayerScripts.Client (default.project.json:5-36). The server bootstrap creates remotes, requires GameService, wires RemoteEvent and prompt handlers, and loads one player profile/run per Player (src/server/init.server.lua:37-50; src/server/GameService.lua:71-149). Runtime services apply combat, progression, world, and profile mutations; clients perform input, movement prediction, UI, animation, and presentation (src/client/init.client.lua:35-98). A singleton Workspace.GameWorld and global enemy registry coexist with per-player RunState, which is a material session-isolation discrepancy (src/server/StageFlowService.lua:56-110; src/server/WorldBuilder.lua:152-161; src/server/EnemyService.lua:19-24). Persistent records use Roblox DataStore FloridaMan_Meta_v2 key u_\<Player.UserId\>, with fallback reads from FloridaMan_Meta_v1 and an in-process cache (src/server/MetaService.lua:17-25; src/server/MetaService.lua:54-55; src/server/MetaService.lua:150-173; src/server/MetaService.lua:343-352). The parent compiler evidence identifies a startup-blocking reserved identifier at src/server/HazardService.lua:131, required by GameService at src/server/GameService.lua:19; runtime scenarios are latent/conditional on a runnable build with these same handlers, not evidence of currently live exploitation.

### Assets

- Server-issued player identity and actor/resource association: Roblox supplies the Player argument to OnServerEvent; currency, unlock, and state mutations are looked up by that Player rather than a payload user ID (src/server/GameService.lua:210-271; src/server/RunContext.lua:21-38).
- Gameplay entitlement integrity: item offer membership, itemSlots, persona unlocks and rarity, weapon unlocks, and Sunburn costs. Draft application checks catalog membership/slot capacity but has no retained offered-ID set (src/server/DraftService.lua:51-71; src/server/DraftService.lua:89-109); weapon equipping validates unlockedWeapons and catalog membership (src/server/CombatFacade.lua:110-122).
- Persistent progress and preference data at DataStore FloridaMan_Meta_v2/u_\<Player.UserId\>: deaths, Sunburn, unlockedPersonas, bestStageIndex, and settings (src/server/MetaService.lua:17-18; src/server/MetaService.lua:54-55; src/server/MetaService.lua:343-349). Purchased personaRarity is absent from that payload although the upgrade consumes stored Sunburn (src/server/HubService.lua:161-168).
- Availability and integrity of the shared GameWorld, global enemy set, turtle objectives, pickups, gates, and per-player stage/run state (src/server/StageFlowService.lua:56-110; src/server/EnemyService.lua:19-24; src/server/EnemyService.lua:318-343; src/server/WorldBuilder.lua:152-161).
- Authoritative combat damage, i-frame and shield state, and cooldown limits held in server memory (src/server/CombatService.lua:21-26; src/server/CombatFacade.lua:64-91), plus the trusted position/facing evidence used for attacks and progression (src/server/AttackService.lua:80-98; src/server/StageFlowService.lua:420).
- Shared server resources: DataStore request budget, tick availability, outbound UI event capacity, and retained session memory. SyncSettings directly triggers Save; the simulation pump is shared and sequential (src/server/GameService.lua:250-298; src/server/MetaService.lua:20-25; src/server/MetaService.lua:320-360).
- Telemetry correctness and intended text-only product behavior. AnalyticsService receives named custom events, but the current adapter omits payload dimensions (src/server/FunnelService.lua:58-69). User-origin requirement: no audio and necessary conversations in small popup text; older implemented server/client audio paths remain (src/server/WorldBuilder.lua:1301-1324; src/client/init.client.lua:35-36; src/client/init.client.lua:96-98).

### Trust Boundaries

- Untrusted player client -\> server RemoteEvents: a legitimate player can issue command names/arguments and timing; server-supplied Player identity must bind lookup and authorization. Type/key validation exists on settings, draft, shop, and equip, while only attack/skill/dodge use token buckets (src/shared/Remotes.lua:6-31; src/server/GameService.lua:169-271; src/server/DraftService.lua:89-105; src/server/HubService.lua:97-108; src/server/CombatFacade.lua:110-118).
- Server-generated draft -\> client display -\> client selection -\> server inventory grant: the offer set must constrain the returned choice. Current roll local variable is sent to the client and discarded; the mutation checks only any valid catalog ID and available slots (src/server/DraftService.lua:51-71; src/server/DraftService.lua:89-109).
- One player's lifecycle -\> other players' world/resources: each InitPlayer schedules LoadHub; LoadHub/LoadStage clear all enemies and rebuild the same Workspace.GameWorld without session identity, while run state and wave flags remain per Player (src/server/GameService.lua:76-95; src/server/GameService.lua:129-130; src/server/StageFlowService.lua:56-110; src/server/WorldBuilder.lua:152-161; src/server/EnemyService.lua:100-128). This boundary requires multiple players on the same server; actual deployed capacity is unverified.
- Client-owned character physics -\> authoritative progression/combat: InitPlayer sets HumanoidRootPart network ownership to the player; attacks use its replicated position/facing and waves use X/stage.length (src/server/GameService.lua:99-119; src/server/AttackService.lua:80-98; src/server/AttackService.lua:114; src/server/StageFlowService.lua:420-431). Responsiveness belongs on the client; progression/target validity must remain server decisions. Complete movement-envelope validation is assigned to the companion audit.
- Server profile domain -\> Roblox DataStore provider: key derivation uses server Player.UserId; cloud reads, migration, memory fallback, and SetAsync occur only in MetaService. Read failure does not mark a profile read-only and Save does not use a version/session conflict condition (src/server/MetaService.lua:150-173; src/server/MetaService.lua:215-258; src/server/MetaService.lua:320-375). No application secret material is passed or stored in source.
- Accepted profile mutation -\> yielded save snapshot -\> unload/shutdown: concurrent saves are rejected by saving\[player\], successful older writes clear dirty unconditionally, and Unload drops bookkeeping after a potentially rejected forced save (src/server/MetaService.lua:325-327; src/server/MetaService.lua:343-375). This is primarily durability/correctness unless a separate attacker boundary and meaningful unauthorized gain is established.
- Server domain events -\> client presentation: StateUpdate, Toast, ShowDraft, ShowNewspaper, ShowTagline, ShowCredits, and PlaySound are server-sent events; clients display them and keep local snapshots (src/server/RunContext.lua:46-90; src/client/init.client.lua:49-98). Client UI presence is not authorization for inventory/progression commands; local accessibility preferences are legitimate presentation state, not a paid entitlement system.
- Domain analytics -\> official Roblox AnalyticsService: server FunnelService emits local diagnostic text and LogCustomEvent(player, event, payload.value); no HTTP endpoint or third-party SDK is involved (src/server/FunnelService.lua:58-69). Provider delivery must be distinguished from Output logging.
- Privileged developer build/publish -\> Roblox experience: rokit.toml:1-2 pins Rojo 7.7.0; default.project.json maps source/Instances; scripts/check_invariants.sh:1-18 checks local text patterns. Publishing and live capacity/API/streaming settings are manual operator workflows documented in docs/PUBLISH_CHECKLIST.md, not exposed to game clients. An attacker is not assumed to control the repository, operator account, or publishing credentials.

### Attacker Capabilities

- Conditional on normal server startup, an ordinary authenticated Roblox player can call exposed client-to-server RemoteEvents with arbitrary primitive/table argument values and timing, including valid-but-unoffered catalog item IDs, unchanged settings, and stale interaction requests; no arbitrary Player identity or server table write is assumed (src/server/GameService.lua:169-271).
- A modified local client can control its own presentation and character movement inputs/network-owned character physics; it cannot thereby directly modify server-only RunContext or CombatService tables. Any new gain must follow server reliance on this client-controlled evidence (src/server/GameService.lua:99-119; src/server/CombatService.lua:21-26).
- A legitimate player can join, start a run, trigger valid combat/shop/draft actions, reset/leave/rejoin, and race its own commands. If multiple players are admitted, these actions may interact with other players' shared world resources (src/server/GameService.lua:129-130; src/server/HubService.lua:24-61; src/server/StageFlowService.lua:56-110).
- A client does not have DataStore credentials, direct access to cloud keys, script/repository write access, published-experience configuration privileges, another player's account, or control of Roblox services. Provider failures and server shutdown are environmental fault scenarios, not attacker capabilities by assumption.
- Potential meaningful gains under investigation are unoffered item entitlement, interference with another run's world/progress, and disproportionate use of shared persistence/UI budgets. Self-only text spam, user preference changes, and intended hub operations are not automatically security vulnerabilities.

### Security Objectives

- Bind every command to the server-supplied player and its allowed run/session/phase, validate argument shape and catalog/reference ownership, and authorize grants against the exact current server offer or transaction (src/server/GameService.lua:237-247; src/server/DraftService.lua:89-109).
- One player's join/death/transition cannot destroy, rescue, clear, scale, or grant rewards from an unrelated player's run. Either enforce and verify single-player deployment or make session ownership explicit throughout world, enemy, objective, reward, and lifecycle paths (src/server/StageFlowService.lua:56-110; src/server/EnemyService.lua:19-24).
- Combat i-frames, cooldowns, damage, legal target/progression checks, inventory limits, currency costs, and unlock decisions remain server-authoritative. Replicated/local UI and client physics are evidence or projections, never sufficient entitlement authority (src/server/CombatService.lua:81-99; src/server/CombatFacade.lua:64-91; src/server/StageFlowService.lua:420).
- Never overwrite an unknown existing profile after a failed read; preserve final accepted mutations across concurrent saves, migration, unload, shutdown, and overlapping servers. Currency spends and acquired tiers must persist atomically with explicit field/version policy (src/server/MetaService.lua:150-173; src/server/MetaService.lua:320-375; src/server/HubService.lua:161-168).
- Bound command rates, no-op writes, retries, event queues, cache retention, and work in the simulation pump so one client or slow provider cannot exhaust shared resources or stop other sessions (src/server/GameService.lua:250-298).
- User-origin product requirement: no runtime audio creation/playback or unmute paths; present every necessary conversation through small, readable, dismissible/advancable popup text. Enforce this in one presentation policy and meaningful source/runtime release checks, replacing older SFX-permitted documentation.
- Telemetry must distinguish successful provider delivery, failure, and local-only logging; KPI denominator/timeout/abort semantics must match reported metrics. Release validation must separate syntax/build, structural lint, static source review, and executed gameplay evidence (src/server/FunnelService.lua:58-69; scripts/check_invariants.sh:1-18).

### Assumptions

- Source revision is 1bff8c516fd0dfed08f991e0c23c008c665f707d. Parent compiler evidence reports src/server/HazardService.lua:131 uses the reserved identifier until; GameService requires it at src/server/GameService.lua:19. Existing handlers are therefore analyzed as latent source paths conditional on repairing that syntax blocker. No currently live exploitable deployment is claimed.
- Roblox is the identity, replication, DataStore, and analytics provider. Its platform/service compromise is excluded. Actual published place/universe identity, max players, API permissions, streaming configuration, datastore data, asset ownership, and telemetry delivery are not observable from this repository.
- Multiple concurrent players are supported syntactically by Players iteration and per-player state, but the repository does not enforce a one-player capacity; the actual deployment setting is an unresolved prerequisite for cross-player impact (src/server/GameService.lua:277; default.project.json:1-65).
- The current profile resource is FloridaMan_Meta_v2/u_\<Player.UserId\>, fallback resource is FloridaMan_Meta_v1/u_\<Player.UserId\>, and fallback memory is a process-local map keyed by UserId. These are distinct resources and no memory retention guarantee survives server loss (src/server/MetaService.lua:17-25; src/server/MetaService.lua:54-55; src/server/MetaService.lua:150-173).
- docs/AUDIT_N2.md:30-31 describes safe loads/saves and re-entrancy as PASS; actual code lacks read-failure write quarantine, queued final saves, and revision-aware dirty clearing (src/server/MetaService.lua:215-258; src/server/MetaService.lua:325-375). Historical source-check passes are not runtime proof.
- Persistent schema omits personaRarity while UpgradePersona spends persistent Sunburn (src/shared/Types.lua:21-36; src/server/HubService.lua:161-168; src/server/MetaService.lua:343-349). Whether weapon unlocks/loadout selection should persist is an explicit product decision; current session retention differs from fresh-join retention.
- Current user instruction supersedes old documentation that permits combat SFX and ambience. Runtime still starts AudioDirector and creates server Sound templates (src/client/init.client.lua:35-36; src/server/WorldBuilder.lua:1301-1324). No audio source changes were made during this audit.
- No application-owned authentication, payment/marketplace entitlement, external HTTP/provider integration, uploaded-code execution, credential issuance, or language-model memory/control subsystem was found in reviewed runtime sources. Local accessibility attribute changes do not constitute an auth bypass merely because they are client-optimistic.
- This independent architecture workstream inspected current source offline and did not execute Roblox gameplay, attack payloads, cloud writes, multiplayer sessions, or provider APIs. The parent owns formal security validation and final canonical findings. Architecture mapping by itself is not full security-audit file coverage.

## Findings

| Finding | Severity | Confidence | Detailed write-up |
| --- | --- | --- | --- |
| [Draft selection grants an item absent from the server offer](#finding-1) | medium | high | inline below |
| [A joining player's lifecycle destroys other active players' world](#finding-2) | medium | high | inline below |
| [High-altitude client positions permit melee outside enemy attack range](#finding-3) | medium | medium | inline below |

### Confidence Scale

| Label | Meaning |
| --- | --- |
| high | Direct evidence supports the finding with no material unresolved blocker. |
| medium | Evidence supports a plausible issue, but material runtime or reachability proof remains. |
| low | Evidence is incomplete and the item is retained only for explicit follow-up. |

<a id="finding-1"></a>

### [1] Draft selection grants an item absent from the server offer

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | Independent source trace and parent validation establish the missing offer membership check and authoritative inventory mutation; runtime remains untested. |
| Category | incorrect-authorization |
| CWE | CWE-863 |
| Affected lines | src/server/DraftService.lua:94-100, src/server/GameService.lua:237-238 |

#### Summary

A modified player client can choose any catalog-valid item during a legitimate draft because the server discards the offered-ID set and authorizes only catalog membership. This bypasses rarity/offer rules for server-issued progression.

#### Root Cause

The domain rolls a limited offer, sends it, and retains only awaitingDraft. On return, itemId is checked against the entire catalog rather than that offer before inventory mutation.

**Client item selection** — `src/server/GameService.lua:237-239`

The client supplies itemId; Roblox supplies the owning Player. The gateway forwards the selection to DraftService.

```lua
	Remotes.Get("PickDraftItem").OnServerEvent:Connect(function(player, itemId)
		DraftService.PickDraftItem(player, itemId)
	end)
```

**Offer sent without retention** — `src/server/DraftService.lua:51-71`

The generated choices remain in a local variable and client payload; the later command cannot consult an authoritative allowed-ID set.

```lua
	s.awaitingDraft = true
	local dailyLuck = Balance.DailyLuckBonus()
	local picks = Items.RollDraft(RunContext.GetRng(), s.luck + dailyLuck, Constants.DRAFT_CHOICES)
	if math.abs(dailyLuck) >= 0.01 then
		local pct = math.floor(dailyLuck * 100 + (if dailyLuck >= 0 then 0.5 else -0.5))
		RunContext.Toast(player, string.format("Florida Forecast: %+d%% draft luck today", pct))
	end
	local payload = {}
	for _, it in picks do
		table.insert(payload, {
			id = it.id,
			name = it.name,
			description = it.description,
			rarity = it.rarity,
			inscription = it.inscription,
			statText = it.statText,
		})
	end
	Remotes.Get("ShowDraft"):FireClient(player, payload)
	FunnelService.Mark(player, "draft_open", { stage = s.stageId })
	RunContext.PushState(player)
```

**Catalog-only grant** — `src/server/DraftService.lua:89-109`

A valid itemId passes catalog checking and is inserted into authoritative inventory. Slot/phase guards do not bind it to the offered choices.

```lua
function DraftService.PickDraftItem(player: Player, itemId: unknown)
	local s = RunContext.GetState(player)
	if not s or not s.awaitingDraft or typeof(itemId) ~= "string" then
		return
	end
	if not Items.Get(itemId) then
		return
	end
	if #s.items >= s.itemSlots then
		RunContext.Toast(player, "Item slots full — draft skipped")
	else
		table.insert(s.items, itemId)
		local it = Items.Get(itemId)
		if it and it.healOnPickup > 0 then
			s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
		end
		RunContext.ComputeStats(s)
	end
	s.awaitingDraft = false
	FunnelService.Mark(player, "draft_pick", { item = itemId })
	advanceAfterDraft(player)
```

#### Validation

The returned client selection reaches table.insert after type, phase, catalog and capacity checks; no offered-ID state or membership comparison exists. LabBadge is a catalog-valid unoffered choice when absent from the three displayed options.

Validation method: independent baseline plus parent static source trace

**Client item selection** — `src/server/GameService.lua:237-239`

The client supplies itemId; Roblox supplies the owning Player. The gateway forwards the selection to DraftService.

```lua
	Remotes.Get("PickDraftItem").OnServerEvent:Connect(function(player, itemId)
		DraftService.PickDraftItem(player, itemId)
	end)
```

**Offer sent without retention** — `src/server/DraftService.lua:51-71`

The generated choices remain in a local variable and client payload; the later command cannot consult an authoritative allowed-ID set.

```lua
	s.awaitingDraft = true
	local dailyLuck = Balance.DailyLuckBonus()
	local picks = Items.RollDraft(RunContext.GetRng(), s.luck + dailyLuck, Constants.DRAFT_CHOICES)
	if math.abs(dailyLuck) >= 0.01 then
		local pct = math.floor(dailyLuck * 100 + (if dailyLuck >= 0 then 0.5 else -0.5))
		RunContext.Toast(player, string.format("Florida Forecast: %+d%% draft luck today", pct))
	end
	local payload = {}
	for _, it in picks do
		table.insert(payload, {
			id = it.id,
			name = it.name,
			description = it.description,
			rarity = it.rarity,
			inscription = it.inscription,
			statText = it.statText,
		})
	end
	Remotes.Get("ShowDraft"):FireClient(player, payload)
	FunnelService.Mark(player, "draft_open", { stage = s.stageId })
	RunContext.PushState(player)
```

**Catalog-only grant** — `src/server/DraftService.lua:89-109`

A valid itemId passes catalog checking and is inserted into authoritative inventory. Slot/phase guards do not bind it to the offered choices.

```lua
function DraftService.PickDraftItem(player: Player, itemId: unknown)
	local s = RunContext.GetState(player)
	if not s or not s.awaitingDraft or typeof(itemId) ~= "string" then
		return
	end
	if not Items.Get(itemId) then
		return
	end
	if #s.items >= s.itemSlots then
		RunContext.Toast(player, "Item slots full — draft skipped")
	else
		table.insert(s.items, itemId)
		local it = Items.Get(itemId)
		if it and it.healOnPickup > 0 then
			s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
		end
		RunContext.ComputeStats(s)
	end
	s.awaitingDraft = false
	FunnelService.Mark(player, "draft_pick", { item = itemId })
	advanceAfterDraft(player)
```

Limitations:
- Static source validation only. HazardService.lua:131 currently blocks initialization; the path is latent until that independent syntax defect is repaired. No live Roblox exploit execution was performed.
- A single offer still grants at most the capped choice; current one/two item caps make three-item sets unreachable.

#### Dataflow

PickDraftItem remote -\> DraftService.PickDraftItem -\> Items.Get -\> s.items insertion/stat computation

- **Source:** client-controlled itemId

- **Sink:** server RunState.items

- **Outcome:** A selected item bypasses the generated offer's entitlement rules.

#### Reachability

Requires an initialized player's pending draft and free item slot. The server-supplied Player limits changes to the caller; no arbitrary user key is accepted.

#### Severity

**Medium** — Constrained game entitlement/integrity impact for the caller; server identity, slot count and draft phase limit the scope. No paid entitlement or cross-account access is claimed.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Retain an immutable server-owned offer with allowed IDs, session/stage/offer identity, and consumed state; validate exact membership and consume atomically through one inventory grant operation.

Tests:
- Reject a valid Legendary ID absent from the offer without granting or advancing.
- Accept each actually offered entry exactly once; reject stale, replayed, cross-run and duplicate selections.

<a id="finding-2"></a>

### [2] A joining player's lifecycle destroys other active players' world

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | high |
| Confidence rationale | Direct PlayerAdded-to-global-clear source path, independently identified and parent-verified. Multi-client behavior has not been executed. |
| Category | incorrect-resource-ownership |
| CWE | CWE-863 |
| Affected lines | src/server/StageFlowService.lua:67-68, src/server/WorldBuilder.lua:152-155 |

#### Summary

Per-player LoadHub/LoadStage operations clear global enemies and rebuild singleton GameWorld while other players retain their separate run flags. In a server admitting multiple players, one join or transition can remove another run's terrain, objectives and enemies.

#### Root Cause

Run state is keyed by Player, but the global world and enemy registry lack a corresponding session owner. Normal lifecycle authority for one player is therefore applied to resources used by others.

**Every join loads its hub** — `src/server/GameService.lua:129-131`

Initialization schedules a hub transition for the newly joining Player.

```lua
	task.defer(function()
		StageFlowService.LoadHub(player)
	end)
```

**Per-player state clears shared resources** — `src/server/StageFlowService.lua:56-69`

Only this player's state is changed, but enemy/world operations have no session scope and operate on global resources.

```lua
function StageFlowService.LoadHub(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	s.inHub = true
	s.runActive = false
	s.stageId = "Hub"
	s.stageIndex = 0
	s.awaitingDraft = false
	s.awaitingNewspaper = false
	EnemyService.Clear()
	WorldBuilder.BuildStage("Hub", s.deaths)
	RunContext.TeleportPlayer(player, WorldBuilder.GetSpawnCFrame("Hub"))
```

**Singleton world contents destroyed** — `src/server/WorldBuilder.lua:152-161`

The builder locates Workspace.GameWorld and clears its children rather than a world owned by the requesting run.

```lua
function WorldBuilder.Clear()
	local world = Workspace:FindFirstChild("GameWorld")
	if world then
		world:ClearAllChildren()
	else
		world = Instance.new("Folder")
		world.Name = "GameWorld"
		world.Parent = Workspace
	end
	return world :: Folder
```

**Stage changes use the same global owner** — `src/server/StageFlowService.lua:100-110`

Subsequent player stage changes again clear enemies, global scaling and geometry; this is not limited to first join.

```lua
	s.waveFlags = {}
	s.minibossSpawned = false
	s.bossSpawned = false
	s.bossDefeated = false
	s.turtlesRescued = 0
	s.turtlesNeeded = 0
	s.coldOneTaken = false
	s.midRoomState = "idle"
	EnemyService.Clear()
	EnemyService.SetStageContext(stage.index)
	WorldBuilder.BuildStage(stageId, s.deaths)
```

#### Validation

InitPlayer schedules LoadHub for each Player; LoadHub invokes unscoped EnemyService.Clear and WorldBuilder.BuildStage, which calls ClearAllChildren on singleton GameWorld. Other Players' RunContext state is not transitioned together.

Validation method: independent baseline plus parent static source trace

**Every join loads its hub** — `src/server/GameService.lua:129-131`

Initialization schedules a hub transition for the newly joining Player.

```lua
	task.defer(function()
		StageFlowService.LoadHub(player)
	end)
```

**Per-player state clears shared resources** — `src/server/StageFlowService.lua:56-69`

Only this player's state is changed, but enemy/world operations have no session scope and operate on global resources.

```lua
function StageFlowService.LoadHub(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	s.inHub = true
	s.runActive = false
	s.stageId = "Hub"
	s.stageIndex = 0
	s.awaitingDraft = false
	s.awaitingNewspaper = false
	EnemyService.Clear()
	WorldBuilder.BuildStage("Hub", s.deaths)
	RunContext.TeleportPlayer(player, WorldBuilder.GetSpawnCFrame("Hub"))
```

**Singleton world contents destroyed** — `src/server/WorldBuilder.lua:152-161`

The builder locates Workspace.GameWorld and clears its children rather than a world owned by the requesting run.

```lua
function WorldBuilder.Clear()
	local world = Workspace:FindFirstChild("GameWorld")
	if world then
		world:ClearAllChildren()
	else
		world = Instance.new("Folder")
		world.Name = "GameWorld"
		world.Parent = Workspace
	end
	return world :: Folder
```

**Stage changes use the same global owner** — `src/server/StageFlowService.lua:100-110`

Subsequent player stage changes again clear enemies, global scaling and geometry; this is not limited to first join.

```lua
	s.waveFlags = {}
	s.minibossSpawned = false
	s.bossSpawned = false
	s.bossDefeated = false
	s.turtlesRescued = 0
	s.turtlesNeeded = 0
	s.coldOneTaken = false
	s.midRoomState = "idle"
	EnemyService.Clear()
	EnemyService.SetStageContext(stage.index)
	WorldBuilder.BuildStage(stageId, s.deaths)
```

Limitations:
- Static source validation only. HazardService.lua:131 currently blocks initialization; the path is latent until that independent syntax defect is repaired. No live Roblox exploit execution was performed.
- Requires at least two players on the same server. A reliably enforced solo deployment removes cross-player exposure; MaxPlayers/admission is unverified.

#### Dataflow

Player join -\> InitPlayer -\> LoadHub -\> EnemyService.Clear/WorldBuilder.BuildStage -\> GameWorld.ClearAllChildren

- **Source:** ordinary admitted player's lifecycle

- **Sink:** shared world and enemy resources

- **Outcome:** Unrelated active run loses terrain/objectives/enemies and may softlock or falsely clear.

#### Reachability

No forged identity or arbitrary stage name is required. Exposure is conditional on a runnable multi-player deployment; per-player StartRun guards do not isolate world resources.

#### Severity

**Medium** — Concrete cross-player availability and game-integrity impact with ordinary player access, conditional on multiple players being admitted. Actual deployment player limit is unknown.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Choose and enforce solo admission, or bind world roots, enemy registries, objective state and transitions to explicit run/party sessions. A cooperative shared world must transition all participants as one session.

Tests:
- With two clients, joining, dying, starting and finishing cannot remove an unrelated active session's resources.
- Verify deployed player capacity if solo; for co-op validate shared turtle/kill/reward credit and atomic transitions.

<a id="finding-3"></a>

### [3] High-altitude client positions permit melee outside enemy attack range

| Field | Value |
| --- | --- |
| Severity | medium |
| Confidence | medium |
| Confidence rationale | Source establishes client ownership, missing vertical hit validation and asymmetric enemy activation. Physics replication and the full scenario need Studio reproduction. |
| Category | client-side-enforcement |
| CWE | CWE-602 |
| Affected lines | src/server/AttackService.lua:163-165 |

#### Summary

A player controls their character's physics, and authoritative melee accepts horizontal range without attacker-target height validation. Enemy activation uses 3D range, permitting server-confirmed attacks from above the range that initiates enemy retaliation.

#### Root Cause

The server trusts client-owned root position for attack origin and validates only horizontal melee reach. Enemy activation uses a stronger 3D distance constraint, so the player can deal damage from a location that prevents new enemy attacks.

**Client character ownership** — `src/server/GameService.lua:99-110`

The server assigns the character root's network ownership to its player; positions supplied by client-owned simulation are later used for hit resolution.

```lua
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?
		if hrp then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		task.wait(0.3)
		if hrp and hrp.Parent then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
```

**Melee omits height validation** — `src/server/AttackService.lua:154-169`

The hit query checks horizontal melee range and the enemy's lane Z, but not the attacker-target vertical separation or legal motion.

```lua
	else
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			if CombatService.InLaneMelee(origin.X, s.facing, root.Position.X, range) then
				if math.abs(root.Position.Z - Constants.LANE_Z) < 6 then
					applyHit(model, base, knock * 0.45, heavy)
				end
			end
		end
	end
```

**AI measures three-dimensional distance** — `src/server/EnemyService.lua:463-489`

Nearest target distance includes height, unlike player melee. Normal enemy attack range is 8, 14 or 16 studs.

```lua
			for _, plr in Players:GetPlayers() do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local d = (hrp.Position - root.Position).Magnitude

					if char:GetAttribute("AggroPull") == true then
						d *= 0.72
					end
					if d < nearestDist then
						nearestDist = d
						nearest = plr
						targetPos = hrp.Position
					end
				end
			end
			if not nearest then
				continue
			end

			local behavior = (model:GetAttribute("Behavior") :: string) or "chase"
			local speed = (model:GetAttribute("Speed") :: number) or 8
			local facing = if targetPos.X >= root.Position.X then 1 else -1
			model:SetAttribute("Facing", facing)

			local moving = false
			local attackRange = if model:GetAttribute("IsBoss") then 14 elseif behavior == "spitter" or behavior == "firearc" then 16 else 8
```

**Attack initiation requires range** — `src/server/EnemyService.lua:560-566`

An enemy initiates its next telegraph only inside its 3D activation range.

```lua
			if nearestDist <= attackRange then
				local now = os.clock()
				local cd = (model:GetAttribute("AttackCooldown") :: number) or 1.5
				local last = lastAttack[model] or 0
				if now - last >= cd then
					lastAttack[model] = now
					telegraphing[model] = true
```

**No upper-altitude envelope** — `src/server/HazardService.lua:243-260`

Correction preserves X/Y when fixing the lane and handles falls below -2, without rejecting an implausible elevated position.

```lua
	local p = hrp.Position
	if math.abs(p.Z - Constants.LANE_Z) > 2.5 then
		hrp.CFrame = CFrame.new(p.X, p.Y, Constants.LANE_Z)
	end
	if st.runActive and st.stageIndex >= 1 then
		local stg = Stages.Get(st.stageId)
		if p.Y >= 1.5 and p.Y < 40 then
			char:SetAttribute("LastSolidX", p.X)
			char:SetAttribute("LastSolidY", math.max(3, p.Y))
			if stg and p.X > st.checkpointX + 4 then
				st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
			end
		elseif stg and p.X > st.checkpointX + 8 and p.Y >= 0 then
			st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
		end
		if p.Y < -2 then
			triggerSoftFall(player, char, hrp, st, toast, "Soft checkpoint — back on the lane.")
		end
```

#### Validation

Parent inspection confirms X-only melee and enemy-only lane check reach applyHit, while enemy telegraph initiation requires full 3D distance within \<=16. No upper-Y/movement validation path was found in the hazard correction or gateway.

Validation method: independent baseline plus parent static source trace

**Client character ownership** — `src/server/GameService.lua:99-110`

The server assigns the character root's network ownership to its player; positions supplied by client-owned simulation are later used for hit resolution.

```lua
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?
		if hrp then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		task.wait(0.3)
		if hrp and hrp.Parent then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
```

**Melee omits height validation** — `src/server/AttackService.lua:154-169`

The hit query checks horizontal melee range and the enemy's lane Z, but not the attacker-target vertical separation or legal motion.

```lua
	else
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			if CombatService.InLaneMelee(origin.X, s.facing, root.Position.X, range) then
				if math.abs(root.Position.Z - Constants.LANE_Z) < 6 then
					applyHit(model, base, knock * 0.45, heavy)
				end
			end
		end
	end
```

**AI measures three-dimensional distance** — `src/server/EnemyService.lua:463-489`

Nearest target distance includes height, unlike player melee. Normal enemy attack range is 8, 14 or 16 studs.

```lua
			for _, plr in Players:GetPlayers() do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local d = (hrp.Position - root.Position).Magnitude

					if char:GetAttribute("AggroPull") == true then
						d *= 0.72
					end
					if d < nearestDist then
						nearestDist = d
						nearest = plr
						targetPos = hrp.Position
					end
				end
			end
			if not nearest then
				continue
			end

			local behavior = (model:GetAttribute("Behavior") :: string) or "chase"
			local speed = (model:GetAttribute("Speed") :: number) or 8
			local facing = if targetPos.X >= root.Position.X then 1 else -1
			model:SetAttribute("Facing", facing)

			local moving = false
			local attackRange = if model:GetAttribute("IsBoss") then 14 elseif behavior == "spitter" or behavior == "firearc" then 16 else 8
```

**Attack initiation requires range** — `src/server/EnemyService.lua:560-566`

An enemy initiates its next telegraph only inside its 3D activation range.

```lua
			if nearestDist <= attackRange then
				local now = os.clock()
				local cd = (model:GetAttribute("AttackCooldown") :: number) or 1.5
				local last = lastAttack[model] or 0
				if now - last >= cd then
					lastAttack[model] = now
					telegraphing[model] = true
```

**No upper-altitude envelope** — `src/server/HazardService.lua:243-260`

Correction preserves X/Y when fixing the lane and handles falls below -2, without rejecting an implausible elevated position.

```lua
	local p = hrp.Position
	if math.abs(p.Z - Constants.LANE_Z) > 2.5 then
		hrp.CFrame = CFrame.new(p.X, p.Y, Constants.LANE_Z)
	end
	if st.runActive and st.stageIndex >= 1 then
		local stg = Stages.Get(st.stageId)
		if p.Y >= 1.5 and p.Y < 40 then
			char:SetAttribute("LastSolidX", p.X)
			char:SetAttribute("LastSolidY", math.max(3, p.Y))
			if stg and p.X > st.checkpointX + 4 then
				st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
			end
		elseif stg and p.X > st.checkpointX + 8 and p.Y >= 0 then
			st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
		end
		if p.Y < -2 then
			triggerSoftFall(player, char, hrp, st, toast, "Soft checkpoint — back on the lane.")
		end
```

Limitations:
- Static source validation only. HazardService.lua:131 currently blocks initialization; the path is latent until that independent syntax defect is repaired. No live Roblox exploit execution was performed.
- Use a scenario that begins outside enemy activation range; already-started telegraphs may still hit because their own damage check omits height.
- Physical replication and actual earned rewards were not executed.

#### Dataflow

client-owned root position -\> AttackService origin -\> X-only melee -\> server damage and rewards

- **Source:** replicated character position

- **Sink:** authoritative damage/kill progression

- **Outcome:** Combat risk can be bypassed without choosing arbitrary damage.

#### Reachability

Requires a runnable active stage and controllable client-owned character physics; server cooldown, facing and horizontal range limits still apply.

#### Severity

**Medium** — Game integrity/progression bypass constrained to the attacker's character and server-calculated damage/rates. No arbitrary damage, platform privilege or other account mutation is claimed.

Additional runtime or deployment evidence could raise or lower this severity.

#### Remediation

Validate attacker-target vertical/lane separation and obstruction at hit resolution, and validate movement against permitted speed/jump/dash/knockback/teleport envelopes before it authorizes combat or progression.

Tests:
- Reject elevated out-of-volume melee while preserving legitimate airborne attacks within the intended volume.
- Verify movement exceptions for server-approved dash, jump pad, knockback and teleport without allowing impossible altitude or gate skips.

## Reviewed Surfaces

| Surface | Risk Area | Outcome | Notes |
| --- | --- | --- | --- |
| Draft offer authorization | not recorded | Reported | Source-validated offer membership failure; per-player type/phase/cap/once controls remain. |
| Session world ownership | not recorded | Reported | Unscoped per-player lifecycle reaches singleton clear; multiple admitted players is an explicit prerequisite. |
| Client position to authoritative combat | not recorded | Reported | Vertical melee/AI activation asymmetry is source-established; physics replication remains runtime-unverified. |
| Settings persistence budget | not recorded | Needs follow-up | No-op valid settings cause provider writes, but per-player saving serialization and Roblox throttling are counterevidence to claimed global starvation. Product F11 reports the concrete debt. |
| Player identity and server defense state | not recorded | No issue found | Remote Player identity is engine-supplied; profile keys derive from UserId. Damage, i-frames and shields are server-owned. EquipWeapon checks ownership/catalog; local-attribute godmode claim is not established. |
| Custom authentication, paid entitlements and AI control | not recorded | Not applicable | No custom login/OAuth, payment receipt, HTTP provider routing, AI memory, agent tool or control-policy subsystem found. Existing game entitlements are not paid platform entitlements. |
| Profile durability | not recorded | Needs follow-up | Failed-read overwrite, lost dirty revisions and missing shutdown/lease are confirmed product reliability findings; attacker control of provider failures is not assumed. |

## Open Questions And Follow Up

- Verify published MaxPlayers/admission before assigning cross-player deployment exposure.
- Reproduce motion/remote scenarios after resolving the independent HazardService parse blocker.
- Formal security baseline fully reviewed 21 Lua files plus default.project.json; other source was reviewed for product behavior/architecture, not all through an independent security pass. This formal security coverage is partial; the product audit inventories all48 source files.
- Published storage budgets, asset permissions, telemetry and live DataStore behavior remain unverified.
- Returned architecture evidence pending parent validation and independent review.
  - Follow-up prompt: Review deferred unit settings_budget and close its stated proof gap.
