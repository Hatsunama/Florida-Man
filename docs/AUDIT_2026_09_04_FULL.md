# Florida Man — comprehensive audit and release assessment

Audited 2026-09-04, America/New_York. Revision: `1bff8c516fd0dfed08f991e0c23c008c665f707d`.

**Release assessment: HOLD. The current source does not compile completely, and repairing that blocker will expose several progression, camera, persistence, input, and isolation defects. The layers do not yet own the correct responsibilities throughout the application.**

This report supersedes the readiness conclusions in the earlier audits for this revision. It does not imply that all earlier fixes were ineffective: server-owned i-frames, attack recovery, the service split, weapon dispatch, item caps, mobile action buttons, and procedural art work are present. Their integration and acceptance evidence were incomplete.

The current product requirement is **no audio whatsoever, with all necessary conversations delivered in small text pop-ups**. Earlier plans that recommend music, ambience, combat sounds, UI clicks, voice, or large mandatory story presentations are superseded. This audit makes no gameplay changes; it provides the findings, evidence, ownership corrections, and implementation plan.

## Report package and reading order

1. This report: release assessment, consolidated findings, layer ownership, prior-audit reconciliation, and coverage limits.
2. [Full improvement plan](PLAN_2026_09_04_IMPROVEMENTS.md): ordered work packages, dependencies, acceptance criteria, verification matrix, and feasible scope.
3. [Architecture and persistence detail](AUDIT_2026_09_ARCHITECTURE_NOTES.md): source traces, security boundaries, lifecycle, providers, saves, and release controls.
4. [Gameplay detail](AUDIT_2026_09_GAMEPLAY_NOTES.md): movement, interactions, combat, AI, hazards, and edge cases.
5. [Content and presentation detail](AUDIT_2026_09_CONTENT_NOTES.md): catalogs, story, every stage, balance, visuals, options, and UI.
6. [Verification evidence](audit-evidence-2026-09-04/README.md): compiler output, existing check output, camera equation traces, and place/source comparison.
7. [Generated security report](audit-evidence-2026-09-04/security/report.md): three source-validated, medium-severity game-integrity/ownership findings; [findings JSON](audit-evidence-2026-09-04/security/findings.json), [coverage](audit-evidence-2026-09-04/security/coverage.json), and [manifest](audit-evidence-2026-09-04/security/scan-manifest.json). The independent security baseline fully read 21 of 48 Lua files plus the project mapping, so its formal security coverage is explicitly partial. All source received the broader product/architecture workstream review.

The three detailed workstreams are part of the full report. Their findings are grouped below where the same defect crosses subsystems; workstream IDs remain useful for assigning individual fixes. This report's consolidated priorities are the canonical scheduling priorities; workstream severity judgments were made independently and may differ.

## What was actually verified

| Check | Result | What the result establishes |
|---|---|---|
| Compile all 48 source Lua files with official Luau 0.737 | **47 pass, 1 fails** | HazardService fails to parse; the remaining files compile syntactically |
| Existing `scripts/check_invariants.sh` | **160 OK lines, exit 0** | Mostly text-pattern and line-count checks pass; they do not establish functioning features |
| Rojo 7.7.0 build of `default.project.json` | **Pass** | Source can be packaged; Rojo does not reject the discovered Lua syntax error |
| Named service-call connection check | **Missing call found** | `EnemyService.UpdateSpillfatherSlickRing` is invoked but has no definition |
| Scalar execution of current camera equations | **Fail** | Position and frame-rate dependent camera divergence can be reproduced mathematically |
| Existing local place XML compared with source | **48/48 scripts match** | The local place contains the same source defects; it is not an older build |
| Source and prior-audit review | **Completed across the three workstreams** | Concrete source paths, contradictions, and missing owners identified |
| Roblox Studio / two-client / touch-device playtest | **Not performed** | No claim that the game boots, feels correct, looks correct in screenshots, or completes its campaign |
| Live cloud saves, uploaded assets, published analytics, device profiling | **Not performed** | These remain explicit acceptance gates, not assumed passes |

Rojo and the compiler ran against temporary tools/output. The existing place and lock were left untouched. The compiler is not a Roblox-aware type checker. Mathematical traces are not engine playtests. All runtime scenarios below are conditional on first repairing the boot error.

P0 means a release blocker with broad impact; P1 means a major player-facing or state-integrity defect; P2 means a material correctness, integration, or maintainability problem; P3 means lower urgency polish or cleanup. These are product priorities, not CVSS scores. Security severity is separately calibrated in the security review.

## Consolidated actionable findings

### F01 — P0: the hazard module prevents server startup

`src/server/HazardService.lua:131` and `:139` declare a local variable named `until`, a reserved keyword. Luau fails at the first declaration. `GameService.lua:19` requires this module during startup, before player initialization and remote setup complete. Reproduce by compiling that module; the exact diagnostic is in `compiler.json`.

**Owner:** build checks and HazardService. Rename the variables and compile every source file in CI. Acceptance requires a clean compiler run and an engine boot through the first playable frame. Do not consider another successful Rojo build sufficient.

### F02 — P0: a missing boss function can interrupt damage and death cleanup

`src/server/EnemyService.lua:275` and `:280` call undefined `UpdateSpillfatherSlickRing`. The branch runs for minibosses as well as the final boss. Health is already reduced, but the death cleanup follows the missing call. A lethal threshold-crossing hit can leave a zero-health hostile in the alive registry; later damage rejects it and gates can remain blocked.

**Owner:** enemy/boss simulation. Implement a scoped phase transition or remove the invalid connection; separate miniboss and Spillfather behavior. Resolve death before optional presentation work and make cleanup idempotent. Test crossing both thresholds, skipping a phase with a large hit, a lethal crossing, repeated damage, and reward delivery exactly once.

### F03 — P0: the camera equation can move the view far away from the player

`src/client/Controllers/CameraController.lua:127` adds the previous look coordinate to a weighted absolute player coordinate instead of blending two positions with normalized weights. The error scales with world X and timestep. Executing the exact scalar equations at 60 Hz, starting at X=400, moving 18 studs/second for three seconds and then stopping for two, leaves the look target approximately **2,278 studs beyond its expected position**. A small stationary example recovers; that does not invalidate the moving/high-X failure.

**Owner:** camera presentation. Replace the deadzone target calculation, use stable timestep handling, and reset position/velocity/focus/arena lock on character and stage changes. Verify all stage lengths, 30/60/120 Hz, frame hitches, reverse movement, teleports, and death during arena lock. See `camera-math.json`; live visual confirmation is still required.

### F04 — P1: individual players mutate one shared world

`StageFlowService.lua:56–110` clears `EnemyService` and rebuilds `Workspace.GameWorld` for one player's join or stage change. Every player has separate stage flags and objectives, while enemies, scaling, pickups, lighting, and world geometry are global. With two players, B joining can destroy A's active stage. Finishing or dying can likewise interfere, and kill/rescue credit does not consistently follow a session owner.

**Owner:** run/session orchestration. Choose and enforce a single-player release, or introduce explicit shared-party/isolated-session ownership. Pass a session world and encounter registry to builders/services. Test two-client join, death, finish, rescue, reconnect, and simultaneous transitions. The configured production player limit is unverified; this is a conditional multiplayer failure, not a claim that a multi-player place has been observed.

### F05 — P1: a cloud-read failure can replace real progress with defaults or old data

`MetaService.lua:150–173` falls back to v1 after a failed v2 read; `:215–258` can return defaults after read failure. No failed-load write quarantine exists. `StageFlowService.lua:83` immediately persists on hub load, and `MetaService.lua:350` uses `SetAsync`. A temporary read failure followed by a successful write can overwrite a valid profile.

**Owner:** profile persistence. Distinguish confirmed-new, loaded, failed, and incompatible-schema states. Migrate v1 only after a successful v2 read confirms absence. Never publish temporary defaults to a failed-load key. Test read-error/write-success and old-v1/new-v2 cases with a controllable storage adapter.

### F06 — P1: concurrent saves lose mutations and leave-time flushes

`MetaService.lua:325–360` drops a save request while `saving[player]` is true, then clears dirty state after the outstanding yielded write. Newer accepted changes can therefore become falsely clean. `Unload` can drop the live profile while the earlier snapshot is still being saved. A boolean prevents re-entry; it does not provide write ordering.

**Owner:** profile persistence. Use mutation revisions, immutable snapshots, a coalescing queue, and a bounded final flush. Only clear dirty state for the revision successfully written. Test changing currency/settings during an in-flight save, a second save, disconnect, delayed completion, and failures in each order.

### F07 — P1: paid-in-game persona upgrades disappear on rejoin

`HubService.lua:146–171` spends Sunburn and changes `personaRarity`. The MetaProfile schema and save payload omit rarity; initialization restores currency and unlocked IDs only. The spent currency can persist while the purchased tier is lost. Weapons also persist across runs within a process but are not serialized, so their intended lifetime is unclear.

**Owner:** progression domain and profile repository. Persist validated tiers and loadout policy, and apply cost/benefit atomically. Test every tier after a fresh-process rejoin and migration from existing profiles. Decide weapon persistence explicitly rather than inheriting it from whichever table happens to survive.

### F08 — P1: long-run, shutdown, and cross-server save guarantees are absent

`MetaService` has no `BindToClose` flush, bounded autosave, session lease, or version/conflict policy. `SetAsync` can overwrite a newer session's state. In-process fallback cannot protect against process loss; a higher Sunburn amount is not necessarily newer because currency is spendable.

**Owner:** profile repository. Add bounded autosave, graceful shutdown coordination, recovery/backoff, and explicit concurrent-session ownership. A blind substitution of `UpdateAsync` is insufficient without a conflict policy. Test delayed old writes and reconnects; never merge spendable balances by maximum. Roblox documents the relevant storage primitives in [Data stores](https://create.roblox.com/docs/cloud-services/data-stores).

### F09 — P1: clients can select draft items they were never offered

`DraftService.lua:51–71` sends rolled choices without retaining them. `:89–109` accepts any catalog item while a draft is pending. A valid unoffered legendary ID passes. Type, slot, and phase checks are present, but they do not prove offer membership.

**Owner:** draft domain. Store a server-owned offer ID, session/stage identity, allowed IDs, and consumed state. Consume a valid selection once through a common inventory grant operation. Test arbitrary IDs, valid-but-unoffered IDs, stale offers, replay, duplicate clicks, and cross-run use.

### F10 — P2: shop rules and destructive actions rely on UI conventions

`HubService.SmashPersona` and `UpgradePersona` lack an in-hub/valid-shop-phase gate. The equipped-smash branch warns the player to unequip first, then removes the equipped persona anyway. UI visibility does not enforce these rules.

**Owner:** hub economy domain. Validate phase and inventory ownership at the operation itself; use one transactional result returned to the UI. Make smash text match the actual destructive behavior and support deliberate selection first. Test active-run requests and equipped/active/last-persona cases.

### F11 — P2: unthrottled settings requests reach a shared storage provider

`GameService.lua:250–271` saves after every valid setting request, including unchanged values. Only attack, skill, and dodge have token buckets. Repeated settings writes can consume shared request budgets; other commands can produce avoidable response traffic. The current in-flight-save bug is not an acceptable rate limiter.

**Owner:** remote ingress plus profile queue. Add command and aggregate budgets, no-op detection, debounce/coalescing, and bounded responses. Test sustained valid requests without stressing live cloud services. Request shape validation and rate limits are both needed; see Roblox's [client-server boundary guidance](https://create.roblox.com/docs/scripting/security/client-server-boundary).

### F12 — P1: player initialization can miss an already spawned character

`GameService.InitPlayer` yields on profile loading before connecting `CharacterAdded`, and never processes an already present `player.Character`. The initial character can miss ownership setup and `Humanoid.Died` binding. This is especially likely to be missed by fast local-only tests.

**Owner:** player lifecycle. Connect first, bind existing and future characters through one idempotent function, and coordinate profile readiness. Test immediate spawn, delayed load, reset during load, and leave before load completes.

### F13 — P2: delayed work is not tied to the run or stage that scheduled it

Story callbacks, boss completion, hub returns, death transitions, summons, and presentation timers capture mutable player/state references without a consistent session generation or cancellation owner. A callback can operate after a new run, different stage, respawn, or player removal. Arena camera state has a similar lifetime mismatch.

**Owner:** session lifecycle. Add a run/stage generation and task scope, invalidate it on transition, and cancel owned connections/timers. Make death and completion idempotent. Test leave/reset/start/finish races at every scheduled delay and ensure old dialogue/rewards cannot enter a new run.

### F14 — P2: one exception or blocking operation can interrupt the gameplay pump

`GameService` runs wave, pickup, telemetry, hazards, and character projection for every player in one periodic loop. A failing module/callback or yielded persistence path can stall unrelated work. Small orchestrator file size does not mean its execution responsibilities are safe.

**Owner:** server runtime scheduler. Keep simulation non-yielding, enqueue persistence, isolate session failures with visible error reporting, and recover only to a coherent state. Do not wrap everything in silent `pcall`. Test one session's failure while another continues.

### F15 — P2: UI transactions have no consistent readiness and acknowledgement contract

Essential UI arrives as one-shot events. Draft/newspaper UIs can close optimistically before an authoritative result or recoverable state snapshot. Client GUI existence is also used as an input-control rule. This makes delayed initialization, lost/late events, and rejected selections difficult to recover from.

**Owner:** application state synchronization. Introduce a client-ready/snapshot path, monotonically increasing state version, current pending offer/dialogue, and accepted/rejected transaction response. Render and dismiss from state. Verify slow client startup, duplicate events, stale versions, and rejected selection without a softlock.

### F16 — P1: every three-item inscription bonus is unreachable

`Constants.lua:21–24` sets item capacity to one, or two after the first death, while an inscription needs three items. All six set bonuses are impossible through normal capped grants. `DraftService` also skips future drafts when slots fill, with no replace/discard flow. Early random drops can end build development for the remainder of a 20-stage run.

**Owner:** build progression and inventory. Choose a feasible capacity/threshold model, add replacement at capacity, and make reward choices continue to matter. Verify each set can be assembled by a legal sequence; then measure damage, sustain, and cooldown combinations. Do not remove the cap without designing replacement and bounds.

### F17 — P1: most persona unlocks lack a usable equip path

`RunContext.UnlockPersona` only fills the second slot if there is room. The UI/remotes have no deliberate equip-persona operation. Startup and new-run logic choose another unlocked ID by map iteration. Players may unlock or upgrade a persona they cannot select without smashing an existing slot; map ordering is not a loadout policy.

**Owner:** loadout domain and hub UI. Add validated slot assignment, a visible two-slot selector, deterministic defaults, and persistence according to the selected policy. Test all eight personas, duplicate selection, swaps, smash/replacement, and rejoin.

### F18 — P2: late rewards and catalog claims need end-to-end reachability checks

Weapon drop tables now reference the catalog, but reference coverage does not prove a normal playthrough grants and uses each entry. For example, FinaleRocket is granted by the final stage's `FinishStage` path, while killing Spillfather schedules `FinishRun` directly. Unlock timing, automatic equip, save lifetime, and selection all affect accessibility. Exact cases and per-catalog mismatches are in the content report.

**Owner:** reward/progression domain. Move rewards into one idempotent stage-clear transaction, including the finale, and generate reachability reports from the graph. Test every weapon/persona/item effect from unlock through equip, use, death, and rejoin. Distinguish a listed definition from playable content.

### F19 — P1: no-audio is not implemented

`init.client.lua` starts AudioDirector; Settings and Meta defaults set `MuteMaster=false`; WorldBuilder creates sounds; combat, UI, credits, and biome playback remain connected. Muting only dialogue or choosing a default mute would not satisfy the current requirement.

**Owner:** product configuration, client composition, and release verification. Remove audio startup/playback, sound catalog/remotes/creation, sound UI, and obsolete audio acceptance checks. Suppress default character sounds and verify fresh profiles, old profiles, respawns, credits, and all stages remain silent. Do not add music, voice, dialogue beeps, or replacement audio assets.

### F20 — P1: story pop-ups block combat while enemies continue attacking

`InputController.uiBlocking` includes `FM_Tagline`. `StageFlowService.lua:492` sends a story pop-up as a room encounter starts; boss intro and other events do similar work. The server encounter keeps running. This punishes reading essential text and makes the popup a gameplay control policy.

**Owner:** client interaction state and session policy. Make necessary conversation small and nonmodal. If a deliberate pause is ever required, the server encounter must own that pause consistently; GUI naming cannot be the authority. Test attack/dodge/jump/swap while every required line is visible, with keyboard, controller, and touch.

### F21 — P2: large fixed panels and fragile text timing violate the intended conversation flow

Tagline uses 72% viewport width with a fixed height, byte-based typewriting, and fixed auto-dismiss. New text destroys the preceding popup. Newspaper, draft, Steve, credits, and HUD use fixed widths that need viewport review. Full mandatory newspaper storytelling is not the requested small-pop-up delivery.

**Owner:** UI layout and dialogue presenter. Queue necessary beats, wrap by available width, reveal graphemes safely, allow instant reveal and explicit dismissal, and use a compact width/height budget. Move required plot lines into this presenter; optional detailed reading can remain separate. Test long text, small portrait/landscape screens, safe areas, larger text, and overlapping event arrivals.

### F22 — P1: cooldown and boss UI have missing connections

HUD's cooldown task is started at module require and immediately tests `gui`, before `HUD.Init` creates it (`HUD.lua:670–675`). It can exit permanently; labels refresh only when another state update arrives. BossBar is constructed hidden and has no update path. These are functioning-looking UI stubs rather than completed feedback.

**Owner:** HUD lifecycle and presentation state. Start/stop refresh with HUD lifetime, interpolate server deadlines, and subscribe to authoritative encounter boss state. Test cooldown completion during idle periods and all boss phases, including death, respawn, and no boss present.

### F23 — P2: accessibility settings change game mechanics or are only partially applied

ReduceMotion skips hitstop that also mutates character velocity. It therefore changes movement/combat outcome rather than just presentation. Telegraph accessibility is decided in server visuals using shared-world/player preferences; world particles, transitions, and other motion need a complete policy. Existing options do not establish complete keyboard/gamepad/mobile navigation or text accessibility.

**Owner:** presentation settings. Keep simulation outcomes invariant across visual preferences; use per-client telegraph styling with shape/pattern redundancy. Add text size and input hints only where needed, and remove obsolete sound settings. Verify equal damage, cooldowns, travel, and hazards with accessibility options on/off.

### F24 — P1: touch cannot perform the complete core loop

MovementController reads keyboard/gamepad input while disabling default humanoid walking/jumping. MobileControls adds ATK/SKILL/DASH/USE/WPN, but no touch movement/jump bridge and no SWAP. Some buttons directly call remotes while others use the common input path. USE fires two unrelated actions rather than selecting one interaction.

**Owner:** unified input intents and interaction resolver. Support move, jump/hold/release, attack, skill, dodge, swap, equip, and nearest valid interaction through the same intent API. Add responsive touch controls and use acknowledged results. Test the first three stages without keyboard/mouse, then verify every verb on controller.

### F25 — P2: movement and cooldown truth are duplicated

The client caps movement at 23, suppressing valid server-computed speed builds. Dodge prediction uses a fixed cooldown while server item bonuses reduce it. The client rewrites velocity each frame, competing with server conveyor, wind, jump-pad, and dash changes. This makes the stage's mechanics depend on update timing.

**Owner:** movement simulation/prediction. Use one motion configuration and authoritative action deadlines, with explicit external force/impulse channels and reconciliation. Clamp validated outcomes consistently. Test slow/fast personas, speed items, dodge bonuses, lag, wind, conveyors, pads, and transitions.

### F26 — P2: skills can use stale facing

SkillService reads stored facing, while facing is updated through attack/dodge paths rather than every accepted directional intent. Moving left then using skill can still aim right.

**Owner:** action simulation. Establish one validated facing input/snapshot per action; use it for hit query, movement, and visual result. Test each persona moving in both directions without first attacking, plus reversal while buffered or airborne.

### F27 — P1: collision and movement validation do not protect progression

Dash skills teleport a fixed distance without sweeping gates. Several attacks use lane-X proximity without a consistent vertical or obstruction test. In particular, `AttackService.lua:163–165` accepts high-altitude melee while enemy attack initiation uses full 3D distance: a modified client can match X from above the enemy's activation range. Progression also uses client-owned character position without a coherent server movement envelope. Projectile collision samples endpoints rather than sweeping and can tunnel or apply pierce in non-travel order (gameplay GP-20). Roblox explains the implications of client-owned physics in [network ownership and movement validation](https://create.roblox.com/docs/scripting/security/network-ownership).

**Owner:** movement/progression authority and hit-query service. Sweep dashes, validate reachable movement with legitimate teleport exceptions, and require completed encounter/objective state at exits. Use consistent hit volumes for melee/projectile/skill and allow explicit exceptions per attack. Test gate crossing, overhead targets, behind-wall targets, out-of-lane positions, and valid high-speed actions.

### F28 — P1: telegraph geometry and interruption behavior disagree with combat

Enemy telegraph damage uses a maximum of X/Z size and ignores Y; the visible horizontal zone can be narrower than the damage area. Flinch/root is skipped while an enemy is already telegraphing, and pending attacks do not consistently recheck interruption. A net effect can appear to stop an enemy while its scheduled strike still lands.

**Owner:** enemy attack state machine and shared attack geometry. Derive rendering and hit tests from the same attack definition, with explicit interruptibility and vertical rules. Test every behavior, exact boundary positions, jumping over zones, simultaneous telegraphs, flinch/root during windup, and death before release.

### F29 — P2: enemy puddles are visually present but not connected to hazards

EnemyService creates oil-puddle Parts without the `Hazard` attribute consumed by HazardService. The hazards scan ignores them. This is a missing contract, not simply a weak visual effect.

**Owner:** hazard spawning/simulation. Spawn registered hazard definitions with explicit volume, timing, effect, and lifetime; derive visuals from them. Test stepping into every spawned puddle and ensure expiry, resistance, and stage cleanup work.

### F30 — P2: knockback can permanently float anchored enemies upward

`CombatService.ApplyKnockback` increments Y on anchored enemies, while most AI preserves their new Y. Repeated hits can move a grounded enemy away from its combat baseline; targeting distances and hit tests then disagree.

**Owner:** enemy motion. Preserve a ground baseline or use a bounded impulse/return trajectory. Test repeated light/heavy hits on each body shape, enemies at ledges, pooling reuse, and attacks after knockback.

### F31 — P2: cancel windows are advertised but not enforced as an action rule

`cancelAfter` drives a HUD cue, but action handlers do not consistently use `InCancelWindow` to accept/reject transitions. A successful grep for the field did not establish an actual cancel mechanic. Hitstop's repeated per-frame Y velocity multiplication also makes aerial interruption frame-rate dependent.

**Owner:** action state machine. Define startup, active, recovery, cancel eligibility, and priority in one server action timeline. Make visual cues follow accepted state. Apply hitstop to presentation or a frame-rate-independent simulation rule. Test actions before/during/after every cancel boundary at multiple frame rates.

### F32 — P2: spawn caps and encounter completion are not coherent

`StageFlowService.lua:427` uses `math.max(1, room)`, spawning even with zero capacity. Boss adds and summoners bypass a common budget; wave flags are consumed before all requested enemies can be delivered. Midroom global hostile counts can include enemies outside the pocket.

**Owner:** encounter scheduler. Queue wave demand, reserve capacity centrally for all spawners, scope room completion to its encounter, and distinguish queued/alive/resolved enemies. Verify the cap under overlapping waves, summons, boss transitions, and rapid traversal; do not silently delete intended enemy counts.

### F33 — P2, needs engine geometry verification: generated ground does not guarantee the route reaches its exit

`WorldBuilder._BuildGround:971–1049` randomizes segment lengths and replaces selected spans with a gap plus only 55% of that segment. It does not reconcile the final cursor with the fixed stage length; the exit stays at `length - 6`. Platforms are generated independently. The code does not guarantee support under required gates/encounters or a reachable end segment.

**Owner:** level layout generator. Plan the complete route in fixed coordinates, reserve safe spawn/arena/exit landings, then decorate it. Validate deterministic Roblox seeds and maximum-jump reachability for every stage. This report does **not** assert an exact failing stage seed without engine-equivalent generation evidence.

### F34 — P2: a soft checkpoint is not necessarily solid ground

HazardService records `LastSolidX/Y` from a Y-range test, including airborne positions, rather than grounded support. A falling character can be restored over the same void. Trigger logic based on distance from a hazard Part center also fails to represent long hazard volumes consistently.

**Owner:** traversal safety and hazard volumes. Save checkpoints only with verified support and clear body space; use authored safe points as fallback. Test jumps, repeated falls, moving platforms, moving hazards, water timeouts, sloped/raised ground, and rapid direction reversals.

### F35 — P2: pools and delayed enemy work have incompatible lifetimes

Enemy pools reside below GameWorld, which WorldBuilder destroys, while pool arrays and AI maps can retain destroyed models. Telegraph tasks, projectiles, summons, and cooldown maps need cleanup on stage clear and reuse. A nominal pool cap is ineffective if stale entries occupy it.

**Owner:** session resource scope and pooling. Own pools outside destructible stage geometry or clear their indices atomically. Reset every reused field and cancel generation-bound tasks. Soak-test repeated stages/deaths and inspect instance, connection, map, and task counts for bounded growth.

### F36 — P2: global hit presentation can alter unrelated players' motion

`EnemyService.lua:247–253` sends every hit confirmation to all clients. Clients apply local movement hitstop to the event, not only to the actor involved. With multiple players, someone else's hit can stall a bystander. Visual event audience and simulation actor are conflated.

**Owner:** combat events and local feedback. Send actor-specific control feedback only to that actor; replicate observer visuals separately, scoped to the session. Test two attackers, idle observers, different sessions, and multiple targets hit by one action.

### F37 — P3: art exists, but definition count is not visual completion

This is a procedural 3D/2.5D Roblox game, not an imported sprite-sheet game. EnemyFactory provides Part/SpecialMesh silhouettes and procedural motion; personas mostly tint/highlight the default avatar. Uploaded animation IDs and mesh templates are absent from source-controlled assets. That is an acknowledged content gap, not fake asset IDs.

**Owner:** art and presentation. Prioritize silhouette, attack anticipation, contact/landing consistency, visual weapon identity, and readable small-scale enemies. Validate fallback and custom rigs against collision roots. Imported meshes are optional until the core game works; no audio assets are part of this plan. The content report inventories what exists and what remains placeholder/scaffolding.

### F38 — P2: asset scaffolding does not validate shipped art

ArtAssets accepts plausible numeric IDs and clones named Models, but ID syntax does not prove ownership, loadability, rig compatibility, collision correctness, animation permission, or asset availability. Rojo maps empty mesh/animation folders; a Studio-only import may not survive a clean rebuild. Current checks reject some fake IDs, but do not validate real content.

**Owner:** asset pipeline and release manifest. Store/export the actual distributable source, define model/rig contracts, verify fallbacks on failed loads, and build an asset manifest with permissions and dependencies. Test a clean rebuild and a restricted client. Never invent IDs to satisfy a check.

### F39 — P2: a visual effect key selects business logic

`AttackService.lua:27–36` selects foam bonus damage and net rooting from `weapon.vfx`. Renaming a cosmetic identifier can silently change gameplay. Shared data is acceptable, but presentation identifiers must not decide combat rules.

**Owner:** combat definitions. Separate `secondaryEffectId`/mechanics from presentation VFX. Make effect handlers explicit and validate catalog dispatch. Test that cosmetic-only changes leave damage, root duration, hit counts, and range unchanged.

### F40 — P2: world construction owns hazard rules, while broad context owns too many concerns

WorldBuilder embeds hazard damage, timing, push, water/pad, and wind rules while building visuals. RunContext combines state, stats, grants, appearance, transport, and persistence. Dependencies injected as `any` reduce file size without proving interfaces. Settings/defaults/types are also duplicated across shared and server code.

**Owner:** architecture. Keep definitions declarative, domain rules in explicit simulation services, builders concerned with geometry/presentation, repositories concerned with storage, and presenters concerned with UI/appearance. Extract around these ownership failures rather than arbitrary line budgets. Use one schema and typed service contracts.

### F41 — P2: story delivery and recorded progress do not always match the story's claims

Delayed/overwritten dialogue can drop required beats; duplicated toast and Tagline deliveries compete. Turtle escort is described as a stage identity but proximity rescue can complete the objective immediately. Credit text describes turtles rescued “forever” while the counter is reset per stage. Repeated act panels and generic lines can contradict the current beat or reveal information too soon.

**Owner:** story state and objective domain. Track campaign/run/stage facts separately, queue only necessary text, and trigger lines from completed authoritative events. Decide whether escort or immediate rescue is the real verb, then align objectives and instructions. Test all five acts, deaths, skipped optional reading, and truthful ending counters. Preserve the core comedy-to-corporate-conspiracy-to-turtle-rescue arc.

### F42 — P2: analytics loses the fields required to measure progress

`FunnelService.lua:64–67` prints fields locally but calls `LogCustomEvent` with only `payload.value`; the callers generally supply `ok`, stage, elapsed time, or failure location instead. Those dimensions do not reach the provider through this adapter. The pcall hides failures. FTUE failures are emitted only for eventual collectors, excluding players who leave or never complete the step.

**Owner:** analytics adapter and funnel domain. Preserve a typed event schema, map supported provider fields, report adapter errors, count timeouts/abandonments, and reset scopes intentionally. Test the adapter with a fake provider and validate live delivery before claiming KPI readiness. Keep telemetry out of simulation-critical scheduling.

### F43 — P2: tutorial progress measures input claims rather than learned actions

TutorialBeat accepts client-reported key/action names; dodge learning can be marked without a real telegraphed threat. Client flags and server new-run flags use different lifetimes. Hub movement, teleports, or prior inputs can suppress later instruction.

**Owner:** tutorial domain. Teach a short move → jump → hit → evade → pickup → swap sequence from accepted gameplay events, with explicit account/run/stage scopes. Use device-specific small text prompts and a replay option. Test fresh join, first death before each beat, controller/touch, and a player who ignores the tutorial.

### F44 — P2: existing acceptance checks reward implementation tokens and outdated claims

The script checks that symbols, comments, document names, sound code, and file-length budgets exist. It does not compile, run, or verify offer membership, save ordering, reachable sets, complete touch controls, boss cleanup, or an entire stage graph. Old scores call these features PASS despite explicitly deferred live tests. README's HP curve also differs from the actual 0.09/stage coefficient.

**Owner:** release engineering and documentation. Retain a few useful hygiene checks, replace correctness claims with behavioral tests, and generate catalog/balance documentation from executable definitions. Separate compiled, unit-tested, engine-tested, device-tested, and published states. A missing screenshot or failed acceptance gate remains open.

### F45 — P2: repeated work and memory costs are not measured or bounded consistently

The 20 Hz loop reapplies speed/persona appearance and walks world children; hazard scans traverse folders, including irrelevant pooled content. AI and animation repeatedly search instances. Hot-path tables, Parts, billboards, particles, and broadcast events add allocation and replication cost. Some caches retain player/model entries for server lifetime. No profiler evidence establishes a safe mobile budget.

**Owner:** runtime performance and lifecycle. First fix correctness, then cache stable references, register active hazards, update appearance on changes, separate render/simulation cadence, scope broadcasts, and measure before pooling more. Establish frame-time, instance/connection, memory, replication, and long-session budgets; validate representative late encounters on real devices.

### F46 — P1: defeating the boss can finish the campaign before its required rescues

The final stage requires three turtles. `StageFlowService.FinishStage:270–276` checks the requirement, but `OnEnemyKilled:209–215` schedules `FinishRun` directly after Spillfather dies. `FinishRun:346–370` has no equivalent objective predicate. The ordinary boss-first path can show a successful ending before completing the rescues and commonly skips the final stage reward transaction. The credits counter is also stage-local, not the cumulative total described in the text.

**Owner:** session completion and reward domain. Put boss defeat, required rescues, and any other ending prerequisites in one idempotent completion predicate used by every caller. Commit final rewards/counters once, then deliver small ending popups and optional credits. Test boss-first, turtle-first, simultaneous last events, duplicate callbacks, and early dismissal.

### F47 — P2: adding authored animation clips exposes broken lifecycle and fallback rules

`init.client.lua:58–60` calls `AnimController.SetPersona` on every state update. `AnimController.lua:195–199` clears tracks even when the persona has not changed. Its fallback at `:304–306` depends only on whether Attack1 has a syntactically valid ID, rather than whether the requested clip loaded. One uploaded Attack1 can suppress procedural behavior for other missing clips; normal attack acknowledgements can stop active tracks. All current clip IDs are empty, so the authored-track failures are conditional on supplying assets.

**Owner:** animation presentation. Make same-persona updates idempotent, select fallback per clip based on successful load/play, assign locomotion/action priorities intentionally, and coordinate default Animate. Test empty, partial, invalid/denied, and complete registries plus attacks during state updates, swap, jump, and respawn.

## Layer responsibility verdict

**No blanket confirmation is possible. Several boundaries are correctly located, but material rules still leak into presentation, global world state, and provider/transport paths.**

| Layer | Responsibilities it should own | Current verdict and required correction |
|---|---|---|
| Shared definitions | Typed personas, weapons, items, stages, effects, public presentation metadata | Appropriate to replicate public catalogs; separate mechanics from VFX IDs; validate references and remove duplicated schemas/defaults |
| Remote gateway | Player identity from Roblox, payload shape, bounds, ingress budgets, routing | Identity source is correct; budgets and semantic authorization are incomplete. Domain services must still validate offers/ownership/phase |
| Run/session lifecycle | Participants, run generation, stage/encounter state, transitions, task cleanup | Incorrectly divided between per-player flags and global world/enemy state; introduce one session owner |
| Combat/actions | Damage, invulnerability, cooldowns, action/cancel eligibility, hit queries | Server i-frames/recovery are improvements; visual keys, client motion, stale facing, global feedback, and unconnected phase behavior still leak |
| Movement | Validated motion rules, collision, external forces, prediction reconciliation | Client may predict responsiveness, but duplicated caps/cooldowns and competing velocity writers are not a coherent contract |
| Encounters/AI/hazards | Spawn budget, phase state, attack geometry, hazard effects, objective ownership | Split across attributes, builder literals, delayed tasks, and global registries; consolidate authoritative rule ownership |
| World building | Realize a validated layout and visuals/collision under a scoped root | Owns too many gameplay constants and destroys shared resources. It must not define progression truth by incidental Part presence |
| Inventory/loadout/economy | Legal grants, equip choices, slot/replacement rules, cost/benefit transactions | Hard cap exists; offered-choice authorization, set feasibility, equip path, and persistent upgrade contracts are incomplete |
| Profile repository | Schema/migrations, load state, write queue, conflict policy, retries, shutdown | Provider code is centralized, but mixed with live attributes/notifications and lacks safe write ownership |
| Client state/input | Device intents and local presentation state | GUI existence controls combat; touch directly calls remotes on some routes. Use consistent intents and authoritative transaction results |
| HUD/dialogue/art/camera | Display accepted state, compact readable text, visual feedback, accessibility | Presenters contain simulation-affecting hitstop/control policy; lifecycle and layouts are incomplete. Enforce silence at composition/release level |
| Analytics adapter | Provider mapping, delivery errors, bounded event buffering | Correct provider choice for this product, but dropped fields and biased event scopes undermine the intended metrics |
| Release/build | Compile, type/contract checks, behavior/engine/device evidence, distributable assets | Current text checks and packaging do not enforce correctness; readiness must be derived from actual evidence |
| Auth/payments/AI control policy | Only if the product implements them | No custom login, OAuth, paid entitlements, payments, AI memory, agent tools, or control-policy engine was found. **Not applicable**, not a security certification |

Client preferences are not automatically security vulnerabilities. Likewise, a local client attribute does not automatically become a server-write capability. The older assertion that setting a local IFrame attribute directly grants server godmode is not accepted as proof; the current server-owned i-frame table is the relevant control. Client-owned physics still requires validation wherever position drives rewards or progression. A factory copying authoritative definition fields onto a server-owned enemy is legitimate initialization; the defect is making visual identifiers or incidental geometry decide rules. Moving visual work client-side must preserve authoritative collision and hitbox state.

## What earlier audits missed or overstated

| Previous claim/focus | Current source-backed reconciliation |
|---|---|
| N0/N2 hard item caps and valid grants | Cap exists, but disables every set and future drafting; offer membership absent |
| N1 service extraction / line budget | Files are shorter, but global session ownership, cross-service contracts, and non-yielding runtime are unresolved |
| N2 save hardening | A boolean re-entry guard exists; failed-read overwrite, lost dirty revisions, shutdown, and cross-server writes remain |
| N3 catalog honesty / all weapons | New dispatch/drop tables exist; normal unlock/equip/retention/finale reachability still needs proof |
| N4 dialogue/audio/options PASS | The prior rule allowed SFX; the current requirement forbids all audio. Popups still block combat, and accessibility changes motion |
| N5 stage verbs | Data labels and set pieces exist; pad/water, escort/rescue, wind/conveyors, ground reachability, caps and checkpoints are not validated end-to-end |
| N6 cancel/combat depth | Cancel cue exists without consistent cancel eligibility; missing boss call and geometry/interruption issues remain |
| N7 art pipeline PASS | Honest fallback/scaffolding exists; real assets, permissions, clean-build packaging, collision alignment and device visuals are unverified |
| N8 soft-launch code ready | Compilation fails, HUD connections are missing, provider fields are dropped, and essential integration tests were deferred |
| Earlier concern about no mobile attack | Some mobile action buttons now exist; movement, jump, swap, and unified interaction still do not complete the touch loop |
| Earlier claim of no persistence | DataStore exists now; durability and transactional correctness are the actual problems |

The newly emphasized areas are compiler coverage, the built place, first-character races, full session lifetimes, two-player isolation, offer authorization, cloud fault ordering, profile economics, visual-to-mechanical coupling, cooldown display lifetime, touch movement, set reachability, and asynchronous story/control conflicts.

## Coverage and limits

The audit covers all 48 current source files through the gameplay, content, and architecture workstreams, the Rojo/Rokit mapping, existing check script, README, asset scaffolding, and prior audit/plan claims. The detailed reports enumerate subsystem coverage and stage/catalog analysis. The ignored local place was read as data and compared with source. `_gen` contains ignored historical generation scratch, not a mapped production source; it is not treated as a supported regeneration/release pipeline.

This is an evidence-backed audit, **not a guarantee that no other defects exist**. Syntax and mathematical defects were executed outside the engine; gameplay, visual readability, collision geometry, persistence failures, and exploit scenarios were primarily traced from source. No live account data was changed, no messages were sent to other people, and nothing was published. Unknowns are preserved as tests in the improvement plan rather than reported as passes.

The release gate is the completion of the ordered repair and verification plan, beginning with boot, saves, session ownership, controls, progression, and the silent compact-text requirement. Cosmetic expansion should follow those gates.
