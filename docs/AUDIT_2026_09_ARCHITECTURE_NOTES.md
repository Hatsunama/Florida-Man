# Architecture, trust, persistence, and release audit notes

Audit date: 2026-09-04 America/New_York. Source revision: `1bff8c516fd0dfed08f991e0c23c008c665f707d`.

This is the architecture workstream for the full September audit. It is a read-only source audit; no gameplay source was changed. Findings below distinguish source-confirmed defects from runtime scenarios that still need Roblox Studio or a controlled published test. A security configuration preflight was run separately for the parent scan: ready, with three available worker slots rather than the suggested six. No persistent configuration was changed.

The parent audit subsequently supplied compiler evidence of a startup-blocking syntax error at `src/server/HazardService.lua:131` (reserved identifier `until`), recorded in `docs/audit-evidence-2026-09-04/compiler.json`. GameService requires that module at `src/server/GameService.lua:19`, before normal server initialization can complete. **All runtime scenarios below are therefore conditional on repairing that parser blocker or on an otherwise runnable deployment containing these same reviewed handlers. They are source-backed latent defects, not claims of a currently reachable live exploit.**

## Assessment

The module split improved navigability, and server-owned damage, i-frames, item slot caps, and weapon unlock checks are real improvements. The source nevertheless cannot support the previous claim of a soft-launch-ready build. There are confirmed gaps in cross-player isolation, draft authorization, save safety, purchased progression retention, and lifecycle ownership. File length limits and keyword checks did not test these behaviors.

No application-owned login, external authentication, paid entitlement, payment, HTTP provider, language-model memory, or agent-control feature is present in the reviewed source. Those concerns are **not applicable**, not implied passes. Roblox supplies the `Player` identity to remote handlers. Gameplay entitlements are the server's item, weapon, persona, and currency rules; these are present and require the concrete fixes below.

User requirement for future work: **no audio at all, and every necessary conversation in a small popup text surface**. Older project documentation permits combat SFX and ambience. That older policy is superseded by the current request. Changing defaults to muted would not be an adequate implementation of a no-audio product requirement.

## Findings

### ARCH-01 — P1: per-player run state mutates one global world and enemy population

Evidence: `src/server/StageFlowService.lua:56-83`, `:86-110`; `src/server/WorldBuilder.lua:152-161`, `:1200-1207`; `src/server/EnemyService.lua:19-24`, `:86-88`, `:100-128`, `:180`; `src/server/GameService.lua:129-130`, `:277-278`.

Every player's hub load, stage load, and stage completion clears the same enemy registry and/or rebuilds the singleton `Workspace.GameWorld`. Each player nevertheless has a different `RunState`, wave flags, objectives, and stage index. Enemy scaling is also a single `_stageIndex`. World lighting is global.

Reproduction: player A starts stage 1 and approaches a wave; player B joins. B's deferred `LoadHub` clears A's enemies and stage geometry. A remains `runActive` with stage 1 state and can spawn its next waves into B's hub. Repeat with one player finishing, dying, or entering a turtle stage while the other remains in combat. Rewards route to the last attacker while objective state is per player, so the same design also permits cross-run credit and rescue theft.

Owner/fix: explicitly choose a session model. The smallest release containment is an enforced one-player experience/server configuration that is included in release verification. If multiplayer is intended, add a `RunSession`/party owner containing stage state, enemy registry, objectives, transitions, participants, and a scoped world root. Both WorldBuilder and EnemyService must receive that session explicitly; never select all `Players` or global `GameWorld` for a local run. Shared cooperative runs need shared progression rules rather than independent player stage indices.

Acceptance: two-client join/start/finish/death/rejoin tests cannot destroy or grant another session's assets/progress; lighting, enemies, pickups, rescue ownership, and stage transitions follow the selected model. Current deployed maximum player setting is unknown and must be verified, not assumed from this repository.

### ARCH-02 — P1, security: draft choices are authorized by catalog existence, not by the offer

Evidence: `src/server/DraftService.lua:51-71`, `:89-109`; entrypoint `src/server/GameService.lua:237-238`; a selectable legendary exists at `src/shared/Items.lua:53` (`LabBadge`).

The rolled choices live only in a local variable and client payload. `PickDraftItem` checks `awaitingDraft`, the argument type, catalog membership, and the slot cap. It never retains or verifies which IDs were offered. An altered client can request any existing item, including a legendary item it was not shown, once per draft. Rarity/luck and the offer UI cease to control progression. Existing slot and duplicate-remote guards do not prevent this.

Reproduction: open a draft whose three IDs do not include `LabBadge`; submit that ID through the existing `PickDraftItem` remote. Source shows it reaches `table.insert(s.items, itemId)`.

Owner/fix: DraftService owns a server-side offer `{offerId, runId, stageId, allowedIds, consumed}`. Validate the supplied offer identity and exact membership, consume atomically, then call the single inventory grant function. Retain the offer for reconnect/UI recovery if supported. Decide intentionally whether duplicate owned items are legal; duplicates are not automatically a bug, but the rule must be explicit.

Acceptance: arbitrary, stale, replayed, cross-stage, cross-run, malformed, and double-click selections are rejected without granting or advancing. Each valid displayed choice grants exactly once. Test the exact offer-membership rule, not merely that the source mentions `itemSlots`.

### ARCH-03 — P1: transient cloud-read failures can overwrite an existing profile

Evidence: `src/server/MetaService.lua:150-173`, `:215-258`, `:320-360`; `src/server/StageFlowService.lua:83`; `src/server/RunContext.lua:41-43`.

On a failed v2 `GetAsync`, `readCloud` still reads v1 and can treat older v1 data as a successful current load. With no usable legacy or process memory, `Load` returns defaults. It records no read-failed/quarantined state. `LoadHub` immediately captures and saves the returned profile, and Save calls v2 `SetAsync` whenever the store handle exists. A read outage followed by a successful write can replace the player's real v2 data with defaults or old v1 data. The offline toast does not protect the cloud record.

Reproduction: seed a nondefault v2 profile; make only the first v2 read fail; let legacy read return nil or an older profile and let the subsequent write succeed. Join and allow hub load. Verify the original record survives; currently it need not.

Owner/fix: ProfileService distinguishes `loaded`, `new-confirmed`, `load-failed`, and `read-only-session`. Migrate v1 only after a successful v2 read confirms absence. Never write unknown/fallback state over a possibly existing cloud record. Use bounded retry/backoff, explicit recovery, and a small text popup explaining session-only progress when required.

Acceptance: fault-injected current and legacy reads, read/write recovery order, absent record, corrupt record, and future schema cannot overwrite a valid profile. Test cloud data preservation, not just local fallback availability.

### ARCH-04 — P1: the save re-entrancy guard drops newer changes and leave-time flushes

Evidence: `src/server/MetaService.lua:287`, `:291-303`, `:325-327`, `:343-360`, `:364-375`.

Save A snapshots data and yields inside `SetAsync`. A setting or run capture during that yield marks the profile dirty, but Save B returns immediately because `saving[player]` is true. Save A then unconditionally clears `dirty`, even though the newer state was not in its payload. If the player leaves during Save A, Unload's forced save also returns false, then removes the profile and dirty bookkeeping. The in-flight older write can finish afterward. There is no queued follow-up flush or mutation revision.

Owner/fix: track a monotonic profile revision and the revision of each immutable save snapshot. After a successful write, clear dirty only if the current revision equals the written revision; otherwise queue another write. Coalesce concurrent save requests, and have unload/shutdown await the final bounded flush before dropping memory. Avoid sharing mutable nested payload tables with a yielded write.

Acceptance: a controllable fake store pauses a save; mutate currency/settings/unlocks; request another save; complete writes in several orders; leave during the first save. Final stored state must match the final accepted mutation, with no lost update or use-after-unload bookkeeping.

### ARCH-05 — P1: purchased persona rarity is lost when the player rejoins

Evidence: `src/server/HubService.lua:146-171`; persistent schema `src/shared/Types.lua:21-36`; `src/server/MetaService.lua:43-50`, `:261-289`, `:343-349`; initialization `src/server/GameService.lua:76-95`; default rarity `src/server/RunContext.lua:168`.

UpgradePersona spends Sunburn and raises `personaRarity`. Sunburn is saved; rarity is neither captured, serialized, sanitized, nor restored. Death and a new run preserve rarity within the same server session, which hides the rejoin loss. Rejoin resets starter rarity to Common and makes all other missing rarities fall back to Common. The upgrade benefit disappears while its currency cost remains spent.

Owner/fix: separate persistent progression from ephemeral run state. Add validated persistent persona rarity and explicit migrations. Perform cost deduction and tier change as one authoritative profile mutation. Decide and document whether unlocked weapons and selected loadout persist too: current weapons survive death/new runs but disappear on server rejoin because they are also missing from MetaProfile.

Acceptance: upgrade each tier, save, unload, load in a fresh process, and verify both currency and benefit. Validate migration of older profiles. Test weapon retention against the explicit product decision.

### ARCH-06 — P1: no safe shutdown, periodic autosave, or cross-server write ownership

Evidence: `src/server/MetaService.lua:320-380`; repository search found no `BindToClose`, `UpdateAsync`, autosave scheduler, session lease, or revision-checked storage write. Run captures at `src/server/StageFlowService.lua:95-96` mark dirty without immediately saving.

Writes are concentrated at hub/death, settings, and PlayerRemoving. Progress earned during a long run is exposed to process loss. Normal shutdown has no application-owned final flush. Two servers can overwrite the same user key with unrelated `SetAsync` payloads during reconnect/overlapping teardown. The in-process memory map does not protect against server loss or cross-server last-writer wins.

Owner/fix: one profile repository owns session leases/version conflict handling, bounded autosave, retry/backoff, flush-at-important-mutation, and `BindToClose` coordination. Use the platform's concurrency-aware write API with an explicit conflict policy; adopting `UpdateAsync` without a correct merge/lease policy is not sufficient, particularly for spendable Sunburn.

Acceptance: abrupt process loss has a documented bounded recovery window; graceful shutdown flushes all dirty profiles within its deadline; overlapping sessions and delayed old writes cannot restore spent currency or erase newer unlocks.

### ARCH-07 — P2, security/availability: settings and several presentation commands have no rate limit

Evidence: `src/server/GameService.lua:210-248`, `:250-271`; `src/server/MetaService.lua:291-303`, `:320-360`; `src/server/HubService.lua:92-94`, `:157-164`; `src/server/CombatFacade.lua:118-122`.

Only attack, skill, and dodge use token buckets. Every valid SyncSettings call, even an unchanged value, marks dirty, captures the run, and requests a cloud write. Repeated settings calls can consume persistence budgets and produce throttled saves. TalkCaptainSteve and EquipWeapon generate multiple outbound events without cooldown or no-op rejection; failed upgrade requests can generate repeated toasts. Basic type/key validation is present and should be retained.

Owner/fix: the remote gateway validates shape and enforces per-command and aggregate ingress budgets. The profile service separately ignores no-op mutations and debounces/batches settings persistence. Bounded UI-event queues should not retain attacker-controlled volumes. Do not depend on the save re-entrancy bug as a rate limiter.

Acceptance: burst/repeated/no-op calls remain bounded, legitimate rapid option toggles coalesce to the final value, and combat traffic plus settings spam does not starve other players' saves. A controlled local test is sufficient; do not test this against strangers' live servers.

### ARCH-08 — P2: hub economy commands lack phase checks; equipped Smash contradicts its warning

Evidence: `src/server/HubService.lua:97-143`, `:146-171`; routing `src/server/GameService.lua:243-247`.

Smash and Upgrade check identity/unlock/cost but do not require hub state, reject drafts/credits, or prove an allowed interaction. An old/open shop or altered client can mutate its build mid-run. If the persona is equipped, Smash says it must first be unequipped and then immediately removes it from slots, resets activePersona, and deletes its unlock. The user-visible denial message is not enforced.

Owner/fix: define economy rules in an inventory/progression service, independent of UI availability. If these are hub-only operations, require the authoritative hub phase. Either reject equipped Smash or provide an explicit reviewed destructive choice in the UI and make the text truthful. Recompute dependent character state and persist the accepted mutation through the profile owner. Do not introduce proximity restrictions unless the product actually requires them.

Acceptance: command availability is consistent via prompts, buttons, stale menus, and direct remotes in all lifecycle phases. Equipped Smash leaves the item untouched when rejected. Spend/unlock deletion is atomic and durable.

### ARCH-09 — P2: initial characters can miss server lifecycle binding after a slow profile load

Evidence: `src/server/GameService.lua:71-99`, `:121-128`; `src/server/init.server.lua:46-49`.

InitPlayer yields in MetaService.Load before connecting CharacterAdded. It never calls the same binding function on an already existing `player.Character`. A character created during a slow datastore read, or present when the script enumerates existing players, misses network-owner setup and the Humanoid.Died connection. The tick loop reapplies speed but does not attach the missing death callback. There is also no cancellation check if the player leaves while Load is yielding; a resumed load can rebuild state for a departed player and schedule a hub rebuild.

Owner/fix: a lifecycle service installs player/character listeners before yielding, binds an already present character idempotently, and checks player membership plus an initialization generation after each yield. Use one teardown owner and explicit cancellation for profile loads and deferred work.

Acceptance: delayed load with early character spawn, preexisting character, reset during load, leave during load, and immediate rejoin each produce exactly one death connection and no ghost RunState/profile/world transition.

### ARCH-10 — P2: delayed transitions and death processing are not tied to a run generation

Evidence: `src/server/StageFlowService.lua:79-80`, `:125-138`, `:156-182`, `:210-215`, `:346-371`; `src/server/CombatFacade.lua:34-61`.

Timers capture a player or an old mutable `s`, but do not verify current run/stage identity. A boss-kill timer calls FinishRun even if a lethal hazard/death or other transition replaced the run before the timer fires. FinishRun has no completed/phase check and its delayed LoadHub can later interrupt a new run. KillPlayer only checks that state exists, not whether this life has already been processed or whether it is in an active run; a delayed/duplicate Humanoid.Died callback can count another death against replacement state. Narrative timers can similarly display obsolete act instructions.

Owner/fix: the run lifecycle owns a discriminated phase and generation/transition token. Delayed callbacks and hit/kill events must present their originating run/stage/life identity and be ignored after invalidation. Completion and death become idempotent transitions with one reward/save/event emission.

Acceptance: kill the boss then die before 1.2 seconds; reset in hub; trigger two death paths; leave with narrative timers pending; rapidly restart after credits. No stale popup, duplicate death/reward, or forced hub transition is allowed.

### ARCH-11 — P2: a slow cloud write or one exception can stall the global gameplay pump

Evidence: `src/server/GameService.lua:274-298`; `src/server/CombatFacade.lua:89-90`, `:60-61`; `src/server/RunContext.lua:41-43`; `src/server/MetaService.lua:351-353`.

The shared sequential pump calls hazards, whose damage callback can call KillPlayer and synchronously yield in profile Save. That pauses wave, pickup, hazard, and softlock processing for everyone in the loop for the duration of the cloud operation. An unhandled error in any of these calls terminates the sole spawned loop entirely. Copying a temporary hazard context also permits writeback to a stale RunState if the callback replaces it during the tick.

Owner/fix: keep storage I/O outside simulation ticks; enqueue persistence through its own bounded worker. Take a stable session reference/generation at tick entry and avoid writing it after a transition. Give each session an observable fault boundary and deliberate recovery path, rather than silently swallowing all exceptions or allowing one player to stop all sessions.

Acceptance: inject a five-second store delay during lethal hazard damage; other sessions continue ticking. Inject one controlled per-session fault; it is reported, contained, and does not permanently stop the pump.

### ARCH-12 — P2: runtime truth still leaks from run state into global world queries and duplicated cooldowns

Evidence: `src/server/StageFlowService.lua:420`, `:461-478`, `:515-523`; `src/server/EnemyService.lua:19-24`; `src/server/RunContext.lua:70-75`, `:265-305`; `src/server/CombatService.lua:22-25`, `:165-186`; `src/server/SwapService.lua:59-65`.

The stage controller combines private RunState with mutable world attributes (`Locked`), all-world hostile counts, and client-owned character position to determine progression. CombatService and RunState each keep skill/swap cooldown timestamps; normal run/death reset replaces RunState but does not reset CombatService cooldown tables. Client attributes and state snapshots are another representation of speed/status. This is multiple ownership, not simply useful replication.

Owner/fix: server run/objective state is the sole progression truth; gate Instances render that state. Combat runtime owns each cooldown exactly once and exposes a snapshot for clients. Movement remains responsive locally, but progress/hit eligibility uses a server-reviewed movement envelope with legitimate teleport/dash exemptions. Remove duplicate authoritative tables and define reset behavior explicitly.

Acceptance: death/new run resets intended cooldowns and preserves only intended persistent fields; world attribute changes cannot independently clear an objective; client position/velocity anomalies cannot grant progression outside allowed traversal. Detailed movement/combat tests are in the companion workstream.

### ARCH-13 — P2: required UI state has no explicit readiness, snapshot recovery, or transaction acknowledgement

Evidence: remote list `src/shared/Remotes.lua:6-31`; server state transport `src/server/RunContext.lua:46-85`; initialization send `src/server/StageFlowService.lua:72`; client listeners `src/client/init.client.lua:35-85`; draft transaction `src/server/DraftService.lua:69`, `:89-109`.

Initialization sends transient UI events while the client is still starting controllers and before an explicit ready/snapshot exchange. The protocol has no request-current-state or UI-ready signal, state revision, run generation, or mutation result message. Draft state stores only a boolean, so it cannot resend the exact offer after UI reset; similarly the client cannot distinguish rejected picks or stale acknowledgements. RemoteEvent buffering may reduce some initialization races, but it is not a recovery protocol and no runtime packet-loss/late-listener assertion is made here.

Owner/fix: a typed presentation snapshot includes runId, revision, phase, current offer/newspaper/credits identity, and server clock. Client announces readiness and may request the current snapshot. Commands get an accepted/rejected result with a stable transaction ID; UI closes after accepted state. Treat small dialogue popups as queued presentation events with bounded replay rules.

Acceptance: slow initial client, character respawn, re-created UI, delayed state messages, invalid draft selection, and repeated buttons converge to the server's current state without missing mandatory choices or locking input.

### ARCH-14 — P2: provider telemetry drops the fields needed to interpret the reported KPIs

Evidence: `src/server/FunnelService.lua:58-69`, `:95-102`, `:114-121`; `docs/KPI.md:18-33`; `docs/PUBLISH_CHECKLIST.md` KPI target table.

The Output log includes the full payload, but the provider call only passes `payload.value`. Callers shown in this file provide `ok`, `t_run`, `where`, `held`, `stage`, or `deaths`, not `value`, and no custom-field mapping is passed. Thus the provider never receives the FTUE success/failure discriminator or softlock location/duration through this implementation. The provider call is cast to any, wrapped in pcall, and its outcome is discarded, so source code cannot distinguish successful delivery from silent failure. Whether an explicit nil numeric value is accepted by the current Roblox API requires primary-documentation/runtime verification; the loss of the actual fields is already source-confirmed.

Owner/fix: separate typed domain events from a Roblox analytics adapter. Define supported event values and bounded dimensions, map them using the current official API contract, and record bounded adapter error counters in developer diagnostics. Output logs are a debugging fallback, not proof of successful dashboard delivery.

Acceptance: a fake analytics adapter sees expected value and dimensions for success, failure, death, and both softlock kinds; a published test verifies dashboard events and distinguishes them. No secrets or third-party SDK are necessary.

### ARCH-15 — P2: funnel success and softlock signals are biased by missing lifecycle events

Evidence: `src/server/FunnelService.lua:86-91`, `:105-133`, `:139-164`; `src/server/CombatFacade.lua:44`; `src/server/StageFlowService.lua:56-83`; `docs/KPI.md` versus `docs/PUBLISH_CHECKLIST.md` FTUE definitions.

FTUE success/failure is emitted only when Cold One is eventually collected. Players who abandon, remain stuck, or leave before collecting never emit an FTUE failure; the KPI document defines a collector-only denominator while the publish checklist speaks of all first-run players. Death and hub load do not clear `midgateLockedAt` or `draftOpenedAt`; a player who dies in a locked room and stays in hub can later be recorded as softlocked. Softlock once flags also persist across stage locks until a new run, preventing multiple incidents from being counted as run events.

Owner/fix: define the KPI denominator and lifecycle semantics in one analytics specification. Record first-run start, success, timeout, abort, and end exactly once as appropriate. Clear or close outstanding interaction spans on every death, stage transition, cancellation, and leave. Keep analytics observational; never let a telemetry timeout advance or reward gameplay.

Acceptance: collector within 60 seconds, late collector, quitter, idle player, reset/death in midgate, aborted draft, multiple rooms, and second run all produce the specified counts and no false hub softlock.

### ARCH-16 — P2: tutorial completion is a client-input claim and its flags reset at incompatible scopes

Evidence: `src/server/GameService.lua:186-205`; `src/server/TutorialService.lua:65-99`; `src/client/Controllers/TutorialController.lua:14-44`, `:47-61`; run resets `src/server/HubService.lua:41`, `src/server/CombatFacade.lua:51`; `src/server/RunContext.lua:203`.

TutorialBeat accepts client claims for move/jump/attack/dodge. A Shift press is treated as a clean dodge if attack was previously reported, without checking an active enemy telegraph, accepted dodge, or avoided damage. This currently grants tutorial text only, so it is a correctness issue rather than a currency exploit. The client keeps reported flags for the session while each server NewRunState resets tutorial flags; prompts can repeat without the client ever reporting the already-completed action again. Several comments incorrectly describe movement detection as server-owned.

Owner/fix: local input hints may remain local. Confirm gameplay milestones from accepted combat/movement events on the server, and keep persistent/session/run tutorial state at explicitly chosen scopes. Use one compact popup flow, prioritize essential instructions, and cancel old stage prompts.

Acceptance: failed dodge, dodge with no telegraph, real avoid, gamepad/touch jump, hub-to-run transition, death, and second run each yield truthful, once-per-intended-scope instructions.

### ARCH-17 — P2: release checks prove source tokens, not the behavior previously marked PASS

Evidence: `scripts/check_invariants.sh:1-18`, `:36-44`, `:63-65`, `:75-82`; `docs/AUDIT_N2.md:12-20`, `:30-31`; `docs/AUDIT_PLAN_NEXT_FINAL.md:34-46`; `rokit.toml`; `default.project.json`.

The only checked-in executable verification is a shell script based on `rg` existence/absence and file line counts. For example, the save safety check only looks for `saving[player]`, and the draft check only for `itemSlots`. Both pass while ARCH-02 through ARCH-04 exist. No checked-in behavioral tests, Luau analyzer configuration, formatter/linter gate, or CI workflow was found. Rojo is pinned, but a place build does not execute Luau gameplay or exercise datastore concurrency. Historic smoke results marked PASS with an asterisk explicitly state Studio was not run.

Owner/fix: retain these checks as structural lint with honest names. Add a pinned Luau/static analysis path and headless unit tests for pure state, draft, profile repository, and lifecycle code with fake clock/RNG/store/remotes. Add integration tests in Studio for movement/world/network/device behavior, and release evidence tied to a commit. Replace unsupported PASS claims with implemented / statically reviewed / runtime verified / unverified.

Acceptance: one deliberately broken offered-item check, lost-update save, and cross-session clear each make a meaningful test fail. CI runs formatting/type analysis/unit tests and Rojo build; release checklist requires recorded one- and two-client/device/runtime evidence.

### ARCH-18 — P2: no-audio and popup policy is not owned at a single enforceable boundary

Evidence: `src/server/WorldBuilder.lua:1301-1324` creates Sound objects; `src/server/StageFlowService.lua:532` emits a sound cue; `src/server/SwapService.lua:46` emits a sound cue; `src/client/init.client.lua:32-36`, `:96-98` starts AudioDirector and handles sound requests; `src/server/StageFlowService.lua:361-362` embeds old release/audio policy in player credits.

Current audio paths are deliberate old behavior, not compliant with the user's present no-audio requirement. The world builder owns an audio catalog and server Sound templates; client AudioDirector owns other playback policy; settings can unmute buses. Product policy is scattered across code, options, tests, and documents. Conversation text is frequently sent as both Toast and Tagline, while release metadata appears in the player's credits.

Owner/fix: remove runtime audio creation/playback and audio-related options/cues from the product path under the current requirement; update checks and documentation so future changes cannot reintroduce it. One client dialogue/popup controller owns compact dimensions, queue, duration, skip/dismiss, accessibility, safe areas, and modal priority. Server emits semantic conversation events, not competing transport-specific toasts. Release metadata belongs in developer/release records rather than player narrative.

Acceptance: source checks plus an actual runtime descendant/playback inspection find no active audio paths or unmute controls; every required conversation fits a small readable popup across devices, with no overlapping duplicate channels or lost instructions. Companion UI workstream provides the detailed geometry review.

### ARCH-19 — P3: generic RunContext owns unrelated domain, persistence, transport, and appearance responsibilities

Evidence: `src/server/RunContext.lua:16-18`, `:41-44`, `:46-90`, `:92-147`, `:214-306`, `:308-350`; duplicate item grant in `src/server/DraftService.lua:100-105`; hard-coded content reward map in `src/server/StageFlowService.lua:290-321`; hard-coded upgrade costs in `src/server/HubService.lua:154-168`.

The old god object was split by file, but RunContext now mixes mutable state access, derived stats, inventory rules, toast/state remotes, profile writes, character appearance, and movement status. DraftService duplicates item application instead of using the central grant function. StageFlow contains content unlock data and enemy composition tables; HubService owns rarity order/cost data. This increases drift and makes correct unit testing unnecessarily dependent on Roblox Instances.

Owner/fix: keep a small run store/lifecycle owner; move inventory and derived stats into pure domain functions; keep profile repository and presenter separate; move reward/cost definitions to validated declarative catalogs; leave stage flow responsible for invoking transitions against those policies. Use typed interfaces instead of `deps: any`. Do not create a large number of single-method services just to meet arbitrary line counts.

Acceptance: inventory grant behavior has one implementation for drop/draft/reward; domain tests run without GUI, network, or DataStore; dependency graph is acyclic and explicit; catalog validation covers every referenced ID/cost/reward.

### ARCH-20 — P3: redundant work and unbounded session caches have no measured budget

Evidence: `src/server/GameService.lua:276-294`; `src/server/RunContext.lua:265-305`, `:214-262`; `src/server/MetaService.lua:20-24`, `:245-253`, `:364-375`; `src/server/StageFlowService.lua:537-554`.

At approximately 20 Hz per player, the pump recomputes item inscriptions, status, movement, persona look, BodyColors, Highlight properties, and character attributes whether they changed or not. Softlock monitoring runs at 20 Hz despite its own 1 Hz recommendation. Stage-clear eligibility is evaluated repeatedly through near-duplicate conditions. MetaService retains memory and warning entries for every user encountered for the full server lifetime; there is no eviction policy. A memory-vs-cloud winner is chosen using greater currency/deaths/stage, although currency is spendable and greater value is not evidence of recency.

Owner/fix: recompute derived state on inventory/persona/status changes; expire time-based status via one scheduler; update replicated attributes only on changes; sample noncritical monitoring at an appropriate interval. Use one stage-clear predicate. Define bounded offline cache lifetime/size and version-based reconciliation, not higher currency. Profile before optimizing loops further.

Acceptance: measured frame/tick/allocation/network budgets on representative devices and player counts, plus bounded cache growth across repeated joins. Spend/rejoin reconciliation cannot resurrect currency because an old cache has a larger balance.

## Layer ownership matrix

| Responsibility | Correct owner | Current assessment | Required change |
|---|---|---|---|
| Player identity | Roblox server event identity | Correct: OnServerEvent supplies Player | Never accept player/user identity from payload as authority. |
| External auth, payments, paid entitlement | Dedicated server integration if added | Not present; no finding invented | Keep out of UI/shared code if introduced later. |
| Gameplay item/weapon/persona entitlement | Server inventory/progression domain | Partial: weapon/unlock checks exist; offered-item check missing | ARCH-02, 05, 08. |
| Run/session identity and phase | Server run lifecycle | Incorrect: per-player state with global world, multiple booleans | ARCH-01, 09, 10. |
| World creation | Session-scoped world builder | Partial: geometry ownership sensible, global singleton wrong | Pass explicit world/session roots. |
| Enemy population and reward attribution | Session encounter runtime | Incorrect across players; `_alive` and scaling global | Scope queries/callbacks to run and participants. |
| Objective completion and gates | Server objective state | Partial: mixes private state and world attributes | Gate Instances render objective truth. |
| Combat damage and i-frames | Server combat domain/runtime | Correct high-level placement | Preserve server tables; fix lifecycle/reset/target proof in companion audit. |
| Cooldown truth | One combat runtime | Duplicated between CombatService and RunState | Snapshot a single clock-owned record. |
| Movement feel/prediction | Client controller | Correct placement for responsiveness | Server validates movement used for rewards/hits; do not trust prediction as entitlement. |
| Persistent profile state | Profile/progression domain | Incomplete fields and mutation ownership | Durable rarity; transactional economy. |
| DataStore API, retries, leases | Server profile repository adapter | Correct layer location, unsafe implementation | ARCH-03, 04, 06. |
| Offline memory policy | Profile repository | Undocumented/unbounded and unsafe reconciliation | Bounded versioned cache with read-failure quarantine. |
| Remote shape/rate validation | Server gateway | Partial: whitelists good, coverage incomplete | Typed schemas and command budgets. |
| Remote names/data contracts | Shared definitions | Reasonable | Separate intent, snapshot, and event types. |
| Remote Instance creation | Server bootstrap | Called exactly once on server but function lives in shared | Relocate for clean dependencies; this is not itself an exploit. |
| Options preference UI | Client preference controller | Local a11y optimism is legitimate | Acknowledge persisted settings; no future entitlement decisions in local attributes. |
| Options persistence | Profile repository | Duplicate defaults and eager writes | One definition; coalesced changed-value writes. |
| Story content | Shared declarative catalogs | Mostly correct | Remove hard-coded conversation/release text from runtime orchestration. |
| Conversation display | One client popup presenter | Split Toast/Tagline and large other surfaces | Small popups, priority/cancellation/readability rules. |
| Audio | None under current requirement | Old server and client playback paths remain | Remove audio creation/playback/options. |
| Appearance/animation/VFX | Client presentation; authoritative cosmetic identity from server | Server repeatedly builds appearance in RunContext | Event-driven appearance adapter, keep combat truth separate. |
| Tutorial | Local hints plus server-confirmed gameplay milestones | Input claims treated as achieved actions; flags reset inconsistently | ARCH-16. |
| Analytics domain events | Observational server analytics | Mixed lifecycle/KPI logic in provider module | Separate event semantics from transport. |
| Analytics provider API | Server adapter | Exists but discards dimensions and outcomes | ARCH-14, 15. |
| Build/release verification | Versioned build/CI/release process | Structural grep presented as behavioral assurance | ARCH-17. |
| Shared utilities/types | Pure helpers and contracts where useful | Util is pure; types populated but incomplete/duplicated | No claim that every shared mutation is a security bug; reduce unnecessary dependencies. |
| Memory/control/agent policy | Not an application feature | Not applicable | Repo docs about audit-agent behavior are process text, not game runtime authority. |

## Prior audit reconciliation

| Prior claim | Current verdict |
|---|---|
| GameService was split and is below 400 lines | True structural improvement; 308 lines at audited revision. It does not prove correct session ownership. |
| PendingDamage replaced by a callback | True. Server `SetOnPlayerHit` and CombatFacade damage path exist. |
| Item slot cap/full draft skip | True. This fixes overflow, not offer authorization. |
| Weapon equip remote has a UI path | Current code has client weapon-state wiring; no longer classify it as dead only because an old audit did. |
| Types.lua is empty/hollow | Outdated. RunState and MetaProfile types now exist; persistence shape is still missing purchased rarity. |
| DataStore safe load/save and re-entrancy hardened | Not supported. ARCH-03 through ARCH-06 contradict behavioral safety. |
| Turtle rescue cannot double count | Rescued flag/debounce is real for one model; session attribution and escort bypass remain separate issues. |
| Combat remote rate limits implemented | True for attack, skill, dodge; not all ingress or persistence-triggering commands. |
| No-audio policy satisfied by popup dialogue | False under current user instruction. Old policy allowed combat SFX/ambience. |
| N8 provider KPIs ready | Output instrumentation exists; provider dimensions and failure observability are incomplete. |
| PASS for soft-launch-ready build | Withdraw until release-blocking data/session/authorization issues and runtime gates pass. Historical asterisks explicitly say Studio tests were deferred. |

## Feasible implementation sequence

1. **Contain release risk first.** Choose/enforce session model, freeze wide release, add meaningful regression fixtures for offers, profile failure/saves, and two-player world ownership. Preserve existing profiles before any schema migration; no destructive data cleanup.
2. **Fix progression authorization and storage together.** Persist server offers and transaction IDs; introduce profile load-state quarantine, revisioned save queue, shutdown/autosave, session write ownership, durable rarity, explicit weapon persistence. Make hub mutations atomic and phase-checked.
3. **Install lifecycle ownership.** Bind initial/existing characters safely, cancel departed initialization, add run/stage/life generations, make death/clear/credits idempotent, scope every timer/hit/reward, and remove storage yields from the simulation pump.
4. **Make client/server contracts recoverable.** Typed commands/snapshots/acknowledgements, readiness and snapshot request, one modal/interaction phase, bounded presentation queues. Snapshot one authoritative cooldown/status source.
5. **Honor text-only product behavior.** Remove all audio paths and unmute settings; consolidate necessary conversation into small accessible text popups. Remove release/debug policy text from narrative. Tie tutorial completions to accepted gameplay events.
6. **Finish architecture cleanup driven by these defects.** Extract pure inventory/stats/progression policy, dedicated storage and analytics adapters, session-scoped world/enemy context, validated content rewards/costs. Avoid cosmetic splits that merely reduce line counts.
7. **Repair instrumentation and performance budgets.** Correct FTUE denominator/spans and provider dimensions; expose bounded delivery failures; measure tick/network/allocation costs; make status/appearance updates event-driven and bound caches.
8. **Prove the release.** CI/static analysis plus behavioral tests, full Studio campaign and two-client interaction runs, fault-injected save/rejoin tests, mobile/controller input and popup layouts, no-audio runtime inspection, and published analytics verification against the exact release revision. Replace every unverified PASS with a clear evidence state.

## Required edge-case test matrix

| Area | Minimum cases |
|---|---|
| Profile load | Existing v2, confirmed empty v2 + legacy v1, failed current read + valid legacy, failed both reads, corrupt data, future schema, unknown catalog IDs, leave during load. |
| Persistence | Mutation during save, forced save during save, failed save and recovery, shutdown, server crash, overlapping sessions, old cached high currency versus newer lower currency. |
| Economy | Exact offered item, unoffered valid item, invalid ID/type, replay/expired offer, double click, full inventory, purchased tier rejoin, equipped smash, shop during every run phase. |
| Session/world | Second join, simultaneous starts, one death/finish/leave, both rescue same turtle, kills credited across sessions, different stage indices, global lighting and pickups. |
| Lifecycle | Preexisting character, respawn during loading, double death event, boss kill then death before timer, credits then restart before timer, delayed callback after leave. |
| Transport | Slow client start, UI reconstruction, delayed snapshot, stale command result, invalid pick, spammed no-op settings/talk/equip, legitimate fast option toggles. |
| Analytics | Success/late/abandon/timeout, death during gate lock, two locks in one run, aborted draft, provider rejection/unavailable service, dashboard dimensions. |
| Product contract | Zero audio creation/playback/unmute; all required conversation readable in compact popup on desktop/touch/controller safe areas. |

## Evidence limitations and reviewed scope

Fully read for this workstream: init.server, GameService, RunContext, StageFlowService, DraftService, HubService, MetaService, FunnelService, TutorialService, Remotes, Types, Settings, Util, CombatFacade, SwapService, TutorialController, default.project.json, rokit.toml, check_invariants.sh, README, KPI, publish checklist, and prior N1/N2/final/layer audit documents. Read relevant lifecycle/state/remote sections of client init, EnemyService, WorldBuilder, CombatService, catalog Items, and CaptainSteveUI for cross-boundary confirmation. Other delegates own full combat, level, sprite/art, movement, and UI review.

No Roblox Studio runtime, cloud-write fault injection, live multiplayer playtest, device performance run, production player cap, or dashboard delivery was available to this worker. Scenario descriptions are regression plans backed by current code paths; they are not claimed executed tests. Current source contains no external HTTP/auth/payment integration. Security-relevant findings should be incorporated into the parent's canonical scan artifacts; this companion note is the product-architecture report, not a replacement for that formal report.
