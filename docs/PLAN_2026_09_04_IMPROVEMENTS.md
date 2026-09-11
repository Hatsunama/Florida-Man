# Florida Man — full improvement and verification plan

Planning basis: the [comprehensive audit](AUDIT_2026_09_04_FULL.md), current revision `1bff8c516fd0dfed08f991e0c23c008c665f707d`, 2026-09-04. This is a proposed implementation plan; no fixes have been applied by the audit.

**The first objective is a reliable, silent, fully playable game with truthful progression and small text pop-ups.** Additional art and content should build on that foundation. A count of implemented symbols or completed phase documents is not a release gate.

## Product requirements that apply to every work package

- No experience audio: no music, ambience, voice, combat sound, UI click, text beep, credit swell, or default character sound leakage. Old saved settings must not re-enable it.
- Every necessary conversation appears as a small, readable text pop-up. It must not prevent the player from defending themselves while combat continues.
- The same essential verbs are available on keyboard/mouse, controller, and touch: move, variable jump, attack, skill, dodge, persona swap, weapon selection, and contextual interaction.
- The server owns accepted progression, inventory, economy, encounter objectives, combat results, and action timing. Clients may predict responsive motion and present feedback through explicit contracts.
- Every listed unlock must have a legal path to acquisition, selection, use, and its intended persistence lifetime. Every advertised item/weapon/persona effect needs an actual consumer and a behavioral check.
- Every stage must have a reachable route, objective, exit, recovery point, clear danger language, and a distinct contribution to the campaign.
- Preserve the recognizable Florida comedy, GulfGulp investigation, and turtle-rescue arc. Improve delivery with text and visuals; do not add audio production to the scope.

## Scope, sequencing, and effort

The estimates below are planning ranges for a developer familiar with Roblox/Luau, plus focused art/QA help where indicated. They are not delivery promises. Runtime findings and the chosen session model can materially change effort. Work packages overlap; do not add all ranges mechanically.

| Package | Priority / approximate effort | Dependencies | Main audit findings |
|---|---|---|---|
| W0 Evidence, boot, minimal test harness | Immediate; 1–2 engineering days | None | F01, F02, F44 |
| W1 Silence and compact conversation contract | Immediate; 1–3 days | W0 boot for verification | F19–21, F23 |
| W2 Safe profiles and progression transactions | Release blocker; 3–6 days | W0 | F05–08, F10–11 |
| W3 Session/lifecycle/state boundaries | Release blocker; 2–4 days single-player containment; 5–10+ for session isolation | Decide session model; W0 | F04, F12–15, F35–36 |
| W4 Unified controls, camera, movement | Release blocker; 3–6 days | W0, W3 interfaces | F03, F20, F22–28, F31, F34 |
| W5 Inventory/loadout/reward completeness | Core progression; 3–5 days | W2–3 | F09, F16–18, F39 |
| W6 Combat, enemies, hazards, encounter rules | Core game; 4–7 days | W3–5 contracts | F02, F26–32, F35–36, F39–40 |
| W7 All-stage traversal/objective/story pass | Core campaign; 4–8 days | W4–6 | F18, F20–21, F32–34, F41, F43, F46 |
| W8 Art, animation, HUD, accessibility polish | Quality pass; 4–8 days for the existing procedural art style | W4–7 stable slice | F21–23, F37–40, F47 |
| W9 Performance, telemetry, release controls | Required verification; 3–5 days | Instrument early; finish after W6–8 | F08, F11, F14, F35, F42, F44–45 |
| W10 Campaign/device/soak acceptance | 3–6 QA days plus defects found | W0–9 | All |

A practical first milestone is roughly **7–12 engineering days** to establish a bootable, silent, save-safe, controlled first-three-stage slice, assuming the smaller single-player release path. A robust campaign pass is likely several additional weeks. Multiplayer session isolation and commissioned/uploaded art are separate scope increases. Re-estimate after W0's engine smoke and W2's storage tests.

Parallel work that is useful: persistence while controls are repaired; text/UI after the interaction contract is agreed; art exploration after collision/animation requirements are stable; telemetry adapter tests while campaign QA runs. Avoid two contributors independently rewriting RunContext, session transitions, or movement truth.

## W0 — establish evidence that can reject a broken build

1. Preserve the audited baseline and link each change to an audit finding. Keep the existing place as a comparison artifact; do not treat it as an independent source of truth.
2. Repair both reserved identifiers in HazardService. Compile all mapped Lua files, including shared/UI modules that may only load later.
3. Resolve the missing `UpdateSpillfatherSlickRing` calls. Choose explicit Spillfather phase behavior and a separate miniboss path. Ensure lethal damage cleanup/rewards do not depend on optional phase visuals succeeding.
4. Add a pinned compiler/type-analysis toolchain beside Rojo. Use Roblox definitions for type checking; separate genuine errors from unsupported engine stubs. Remove `any` only where a concrete service boundary can be typed correctly.
5. Introduce a small deterministic test harness for pure rules and injectable adapters: stat computation, offer validation, phase transitions, storage write order, progression graph, and camera math. Do not build a second mock game engine.
6. Retain textual hygiene checks for narrow structural policies, but remove assertions that reward obsolete sound code, marketing text, or a particular implementation comment. A test should not pass merely because a stub has the expected name.
7. Add CI stages: source compile → type/contract checks → targeted behavior tests → Rojo package. Record the commit and exact tool versions. Engine/device acceptance remains a separate required record.
8. Run an engine boot and confirm server initialization, client readiness, profile state, initial character, camera, HUD, bonfire interaction, and stage 1. Capture the actual errors and first actionable screen.

**Done when:** every source compiles; missing methods/types fail automatically; boss/miniboss threshold and lethal-hit tests pass; the initial slice starts in Studio without errors. Packaging success alone cannot close W0.

## W1 — make the entire experience silent and necessary text compact

1. Remove AudioDirector startup and listeners, `PlaySound` transport, server Sound templates, AudioCatalog usage, combat/UI/credits playback, and audio preload/ducking/tween work. Delete dead modules only after verifying no remaining requires.
2. Remove sound settings from the player-facing options. Migrate/ignore old mute fields safely; never let an old profile's `MuteMaster=false` enable playback. Prefer an absent playback pipeline over a mutable mute preference.
3. Disable/suppress default character sounds through the appropriate Roblox character composition path. Verify joins and every respawn. Inspect experience voice/audio configuration without assuming it from the repository.
4. Define one `DialoguePresenter` surface: a small corner or lower-side bubble that avoids the character, telegraphs, HUD, and touch controls. Start with a width clamped approximately to 280–440 px, a safe viewport fraction on narrow screens, and 2–4 readable lines. Tune through screenshots; these are proposed layout budgets, not already-measured dimensions.
5. The presenter receives speaker, text, beat ID, priority, scope/generation, and optional explicit acknowledgement. It owns wrapping, sizing, reveal, dismissal, and queueing. It does not own combat permission or server progression.
6. Essential story delivery is nonmodal. Remove `FM_Tagline` as a combat blocker. If a choice truly requires a paused encounter, represent that as an explicit server-owned state with consistent client controls; ordinary conversation does not need it.
7. Use Unicode-aware reveal (`MaxVisibleGraphemes` or equivalent verified behavior), instant reveal, and a deliberate dismiss control. The first skip reveals; the next dismisses. Avoid duplicate input handlers causing both actions on one press.
8. Queue critical beats without overwriting them. Coalesce incidental toasts; expire stale generation-bound lines. Do not flood the same line into both Toast and Tagline. Give longer necessary lines enough time or explicit acknowledgement.
9. Move required newspaper/Steve/act exposition into short popup beats at safe moments. Retain optional longer reading only if it adds value; it must not be necessary to understand the objective. Ordinary item-selection/shop UI may remain a panel, but its dialogue uses the compact presenter.
10. Replace product-visible implementation jargon such as “N8”, “InEngine_v3”, and internal policy explanations with useful controls/objectives. Keep those details in development docs.

**Done when:** zero experience-owned sound plays in a fresh run, old-profile run, death, respawn, stage transition, boss encounter, or credits. All necessary conversations fit the compact surface at tested viewports, do not cover telegraphs, and allow defensive controls during danger. No voice, soundtrack, SFX procurement, or text beep is included.

## W2 — protect profiles before expanding progression

1. Create an explicit profile lifecycle: loading, loaded-existing, confirmed-new, failed-load/read-only, incompatible-version, saving, closing, closed. Return structured status; do not use a valid-looking default table as evidence of a successful load.
2. Separate the Roblox storage adapter from profile rules. The adapter reads/writes provider data and reports errors; it does not read live character attributes, trigger popups, decide rewards, or silently choose fallback authority.
3. Distinguish failed `GetAsync` from successful nil. Only successful nil can begin new-profile creation or v1 migration. Quarantine failed-load sessions against cloud writes. Decide whether they can play a temporary unpersisted run, with a short truthful status popup.
4. Add a versioned schema containing the progression intentionally retained: Sunburn, persona unlocks, persona rarity, selected loadout if persistent, best stage, settings, and any cumulative turtle statistic used by credits. Define weapon lifetime explicitly.
5. Validate known IDs, uniqueness, finite/ranged numbers, maximum collection sizes, schema compatibility, and defaults. Unknown future schema must not be relabeled and overwritten as the current schema. Preserve or reject unknown fields deliberately.
6. Replace aliased mutable snapshots with immutable payload snapshots and mutation revisions. Record `savedRevision`; if state changes during a write, queue the latest revision. Coalesce repeated save requests without dropping the final accepted state.
7. Implement a session lease or equivalent conflict policy for overlapping servers. Use concurrency-aware storage operations correctly. Currency spends require transaction order; they cannot be merged using maximum value. Refuse an outdated writer rather than restoring spent currency.
8. Add bounded autosave, backoff/retry, important-event flush requests, and graceful shutdown coordination. Unload awaits or hands off a final bounded flush before discarding profile ownership. Report failures without blocking the simulation loop.
9. Make upgrades and smash operations domain transactions. Validate hub phase, known/unlocked persona, equipped-item policy, affordability, tier bounds, and cost/benefit together. Store accepted profile changes and publish one resulting state.
10. No-op settings changes must not create writes. Apply validated visual preferences promptly; debounce their persistence separately. Add a conservative per-player ingress budget and a bounded pending save queue.
11. Replace the memory cache's “higher currency means newer” rule with explicit revision ownership. Bound/evict caches and warnings by lifecycle; a fallback cache must not become a competing authority.
12. Write migrations and failure tests before using production keys. Validate against a controlled test universe/profile, then verify a fresh-process rejoin. No production data rewrite is necessary for the audit.

**Done when:** an injected read failure never overwrites a valid profile; a newer mutation survives an older in-flight save; shutdown and reconnect are ordered; every purchased tier and currency cost survives together; failed-load state is visible and safe. A successful one-time rejoin is necessary but insufficient.

## W3 — give one owner to sessions, transitions, and asynchronous work

1. Decide the supported release model. The smaller path is an enforced single-player server with a documented, verified player limit. A cooperative game needs one party-owned run. Independent players need isolated session worlds/registries or separate servers. Per-player runs sharing one mutable world are not a supported middle ground.
2. Introduce a session identity, generation, participant set, current stage, phase, encounter/objective state, world root, owned tasks, and reward ledger. Existing modules can receive this object incrementally; a whole-repository rewrite is unnecessary.
3. Make WorldBuilder realize a supplied stage under the supplied world root. Make EnemyService/hazards/pickups operate on a supplied encounter/session. Eliminate broad global `GetAlive`/`GetPlayers` queries where they cross session boundaries.
4. Define transitions centrally and make them idempotent. Record an accepted transition before asynchronous work. Each callback captures a generation and verifies it before changing anything.
5. Create a lifecycle/task scope for event connections, delayed callbacks, projectiles, summons, UI requests, telegraph Parts, and pooled models. Cancel on stage exit, run end, player removal, or replacement. Reset all pool attributes and index tables on reuse.
6. Bind the first character as well as later characters, regardless of profile timing. Keep profile readiness, character readiness, client readiness, and current session state explicit. Handle leave/reset during initialization without creating orphan work.
7. Split simulation from persistence/analytics. The simulation tick is bounded and non-yielding. Queue provider work. Isolate a session failure, record diagnostics, and recover to a deliberate state rather than silently continuing a partially applied transition.
8. Define state snapshots and versioning. The client signals readiness and receives the current run, pending offer, objective, loadout, cooldowns, and necessary dialogue. Incremental events carry the state/session version where needed.
9. Commands return accepted/rejected results with a reason and relevant current state. Draft/shop/newspaper UI remains recoverable after a rejection or delayed response. Keep the previous safe screen until the server confirms progression.
10. Scope combat event audiences: actor-specific motion feedback to the actor, observer visuals to appropriate participants, and private inventory/shop information to its owner. An observer must not receive another player's physics hitstop.

| Session phase | Allowed domain operations | Completion rule |
|---|---|---|
| Loading | Readiness/snapshot requests; safe client presentation | Profile, character, world, and client reach coherent readiness |
| Hub | Loadout choice, validated shop transactions, start run, optional dialogue | One accepted StartRun consumes the hub transition |
| Active stage | Movement/actions, context-valid interaction, encounter objectives | Authoritative encounter and objective prerequisites satisfied |
| Reward/offer | Select or replace an item from the exact pending offer | One validated selection or explicit allowed skip |
| Dead/recovering | Dismiss necessary text; controlled respawn/return | One death processed; old tasks cannot grant or advance |
| Ending | Final rewards once; small ending text; optional credits | Completion ledger committed before returning to hub |
| Closing | Bounded save flush and cleanup | Ownership released; callbacks cannot resurrect state |

**Done when:** duplicate requests and delayed callbacks cannot grant twice, move a new run, or mutate a different session. The selected player-count model is tested. Every timer/connection/pool entry has a clear lifetime owner.

## W4 — make controls, movement, and camera consistent

1. Define a single input-intent API for keyboard, mouse, controller, and touch. Buttons produce intents, not direct arbitrary remote calls or accesses to controller internals. Keep action availability in explicit state, not GUI-name searches.
2. Add touch horizontal movement, jump press/hold/release, and persona swap. Verify safe-area spacing, thumb reach, and no overlap with text/HUD. Resolve USE to one nearest valid interactable with a clear label; do not fire start and talk together.
3. Align server/client action deadlines and acknowledged facing. Every skill receives the current accepted direction; a move-left-first scenario must work without an earlier attack. Define attack buffer behavior using the acknowledged recovery state, including the fastest legal builds.
4. Repair the camera deadzone formula and spring integration. Add bounds or stable damping for long frames. Test stationary, continuous movement, reverse movement, high X, event focus, and arena lock. Reset velocities and locks on transition/respawn.
5. Put movement parameters in one definition: base speed, modifiers, acceleration, jump/coyote/buffer, dodge duration/distance, and cooldown bonuses. Remove client caps that silently erase server buffs. Enforce legitimate bounds consistently.
6. Use explicit external-motion contributions for conveyors, wind, pads, knockback, and dash. One motion owner combines them. Choose a prediction/reconciliation contract rather than multiple writers replacing velocity.
7. Sweep dashes against relevant collision and gates; inspect the entire swept attack path when the skill should hit along it. Preserve intended traversal exceptions explicitly per ability. Test dash from both sides and at high frame time.
8. Make grounded/coyote detection use actual support collision groups and valid normals, ignoring decorative/queryable VFX, telegraph planes, pooled models, and noncolliding props. Store only grounded safe checkpoints with body clearance.
9. Keep visual accessibility invariant with respect to simulation. Hitstop should be presentation-only if possible; otherwise apply one deterministic time rule independent of frame rate and ReduceMotion. Do not multiply vertical velocity every rendered frame.
10. Add a movement validation envelope for client-owned physics with explicit authorized teleports/impulses. Validate rewards and gates from session objectives as well as position. Avoid punitive reactions to ordinary lag or legitimate high-speed skills.
11. Fix HUD initialization ownership: start cooldown refresh after Init, stop it on teardown, interpolate server deadlines, and recover after state snapshots. Wire boss state and relevant objective counts.

**Done when:** keyboard/controller/touch can complete stages 1–3 using every essential verb; action availability and cooldowns agree; legal speed/CDR builds work; camera errors remain bounded at all stage coordinates and tested frame rates; hazards and dash cannot bypass locked objectives accidentally.

## W5 — make builds, loadouts, and rewards real choices

1. Give every pending draft a server offer record `{offerId, sessionId, stageId, allowedIds, consumed}`. Check membership and ownership at selection. Do not accept an item merely because it exists in the catalog.
2. Consolidate item grants from drafts, pickups, enemy drops, and rewards. The operation owns caps, replacement, pickup healing order, duplicate policy, stat recomputation, and emitted state. On-hit bonuses run only after a confirmed valid damaging hit.
3. Choose the item model deliberately. A feasible starting proposal is to permit at least one three-piece set before midgame, grow capacity to approximately 5–6 by later acts, and allow replacement at capacity. Alternatively lower thresholds, but verify the resulting combinations. The exact values are tuning hypotheses, not conclusions from current playtests.
4. Keep reward choice alive at capacity: replace a chosen slot, take a useful bounded alternative, or intentionally skip. Do not automatically discard all later drafts. Clearly show the existing item's effects and resulting set counts before replacement.
5. Add a deliberate two-persona equip UI and server operation. Allow selecting any legitimately unlocked persona into a legal slot. Define duplicate persona policy, active-slot behavior, and changes permitted in hub versus run. Persist the selected policy.
6. Put costs, tier progression, grants, and weapon drops in typed domain definitions with one owner. Keep flavor, colors, and VFX separate. Changing a visual key must never grant foam damage or root behavior.
7. Make stage rewards idempotent and shared by all completion paths. Final-boss kill, exit, delayed finish, and credits must converge on the same reward transaction. Resolve FinaleRocket availability so a normal player can use its promised reward according to its intended lifetime.
8. Avoid automatically equipping each unlock in sequence without player intent. Display a small unlock popup and make selection available through the loadout UI. If auto-equip is retained as a tutorial behavior, restrict and explain it.
9. Generate a content contract report: all 8 personas, 28 items, 28 weapons, and every enemy definition → referenced unlock/drop → equip/use route → mechanic handler → presentation handler → persistence policy. Include aliases/unused entries and every inscription set.
10. Update descriptions and unlock hints to match actual behavior. Do not advertise stun, splash, knock resistance, aggro, oil resistance, or a special attack unless the corresponding operation exists and is reachable. Flavor text can remain comic, but `statText` and control hints must be factual.

**Done when:** all advertised build combinations are legally reachable; a full inventory does not end reward progression; unoffered/stale selections fail; every persona can be selected; final rewards and purchased tiers persist as designed.

## W6 — align combat, enemy behavior, and hazard truth

1. Define action timelines with startup, active, recovery, cancellation, direction, hit geometry, and result events. Make the server action state own eligibility; HUD flashes follow the accepted timeline.
2. Create one hit-query representation for lane melee, beams, thrown/ranged projectiles, dashes, and lingering summons. Specify vertical tolerance, obstruction, allied targets, pierce count, and hit-once policy per attack.
3. Sweep projectiles between previous and current positions, sort hits by travel distance, and apply pierce deterministically. Endpoint-only tests can tunnel; table iteration is not impact order. Compare rendered arcs with the actual collision path.
4. Make damage return a structured result: accepted damage, mitigation, shield absorption, kill, and effects. Only accepted results trigger lifesteal/on-hit/currency/combination bonuses. Resolve zero-health and removed targets safely.
5. Give each enemy attack a state machine with explicit windup, release, recovery, interruption, hyperarmor, and death cancellation. Define whether root stops motion only or also cancels attacks; display that consistently.
6. Use the same volume for enemy telegraph and damage. Add visible shape/pattern coding; avoid large invisible X reach produced by the visual Z dimension. Decide what jumping can avoid and encode it consistently.
7. Fix knockback to use a bounded trajectory or ground-relative displacement with landing. Reset baseline on spawn/reuse. Do not accumulate Y on anchored models indefinitely.
8. Introduce a registered hazard definition containing kind, volume, phase, effect, immunity/resistance, force, and lifetime. WorldBuilder requests a hazard by definition; it does not invent its damage/timing while creating a Part.
9. Connect every enemy-created puddle/fire/sludge zone to the hazard registry. Use its actual geometry, not a generic radius around an arbitrary Part center. Check overlap ordering and cooldown rules across multiple hazard types.
10. Build one encounter spawn budget for regular waves, midroom reinforcements, minibosses, boss adds, and summons. Queue unmet demand; distinguish enemies not yet spawned from enemies defeated. Define budget reservations so boss/add behavior remains readable.
11. Scope target selection to active, alive participants in the encounter. Ignore hub/dead/loading characters. Complete rooms from their own encounter ledger, not every hostile anywhere in the world.
12. Give minibosses and Spillfather differentiated move sets with clear phase transitions, rather than merely faster/wider versions. Preserve a modest existing-content scope: first make each advertised behavior true; add new behaviors only where they improve role readability.
13. Move transient client-visible hit flashes, shake, particles, and damage billboards off the authoritative hot path where practical. Emit typed results and let clients present them. Keep server collision/telegraph timing authoritative.

**Done when:** every weapon kind, persona skill, enemy role, phase, and hazard passes its boundary tests; damage matches visible danger; interrupted/dead/out-of-session actors cannot finish old attacks; simultaneous spawns remain within the chosen cap.

## W7 — verify and improve every stage and story connection

1. Split layout planning from realization. Generate a complete traversable route with reserved spawn, encounter, rescue, and exit areas. Allocate gaps within fixed endpoints rather than shortening the total route accidentally.
2. For each of the 20 stages plus hub, generate a layout manifest: start/exit coordinates, supported ground intervals, gaps, platforms, collision doors, encounter triggers, hazards, checkpoints, rescue positions, and planned camera range.
3. Validate reachability with the slowest legal base movement/jump configuration and with status effects that are meant to apply there. Re-run with fast builds and dash to detect unintended skips. Verify ground/space under locked rooms and exits.
4. Repair soft fall: actual supported checkpoint, clear respawn space, safe fallback, brief controlled recovery, no infinite fall loop, no objective skip, and no camera lock inherited from the previous location.
5. Separate turtle objective truth from presentation. Decide whether a stage asks for immediate rescue, escort to a safe point, or both. Do not call proximity pressing E an escort. Define credit for the selected session model and keep turtles allied.
6. Maintain separate counters for current-stage rescued turtles, run total, and lifetime total if used. Credits use the correct counter and only claim what is persisted. Every finale caller uses the same predicate: `bossDefeated AND rescuesComplete`, plus any other explicitly required encounter conditions. Commit final rewards and counters once before ending text. Test boss-first, turtle-first, simultaneous last kill/rescue, duplicate callbacks, and early credits dismissal.
7. Build a necessary-story beat map across five acts: initial comic theft → collar evidence → engineered wildlife → turtle stakes → facility evidence/cover-up → confrontation → truthful rescue outcome. Each beat has prerequisite facts, triggering event, short popup lines, and a delivery scope.
8. Ensure required dialogue is queued at readable moments without taking defensive control. Avoid repeated full act panels or generic Steve lines that reveal future information. Optional banter can vary with deaths/rescues without blocking objectives.
9. Treat the following act identities as design targets to verify and sharpen, not already-proven mechanics:

| Act / stages | Intended playable distinction | Concrete improvement and validation |
|---|---|---|
| Hub | Loadout and run preparation | Deliberate two-slot selection, clear bonfire interaction, safe shop transactions, compact necessary text |
| 1 / 1–5 | Learn verbs and readable timed danger | Teach one verb at a time; early rhythm hazards must be avoidable by learned jump/dodge; collar reveal follows the correct event |
| 2 / 6–10 | Swamp route choice, water/pads, oil/fire roles | Pads and water timeout must actually govern traversal; introduce mixes in safe increments; verify every platform/gap route |
| 3 / 11–12 | Turtle objective pressure | Explicit rescue/escort win condition, safe destination, legible remaining count, no stealing credit across sessions |
| 4 / 13–19 | Facility traversal and enemy combinations | Conveyors and pipe hazards need clear timing/force; vary layouts and encounter objectives rather than only palette and HP |
| 5 / 20 | Conclude learned mechanics and boss phases | Distinct readable phases, valid wind/gap interactions where intended, final turtle/reward bookkeeping, silent ending popups |

10. For each individual stage, assign a primary new/challenged verb and one supporting constraint. Avoid several hazards merely stacking into unreadable damage. The content report's all-stage table is the initial checklist; fill its runtime results from actual play.
11. Add optional recovery and replay controls only after core traversal is sound: restart current run, return to hub safely, replay tutorial, and a developer stage-jump harness for QA. Do not expose developer bypasses as ordinary progression authority.

**Done when:** all stages have a demonstrated start-to-exit route and correct objective/reward transition; every required story connection is delivered in small text; no gate depends on a destroyed/out-of-scope/zero-health actor; completion text matches recorded facts.

## Power scaling and balance pass

Balance work starts after legal loadouts and true effects are fixed. The current formulas alone cannot establish difficulty because unreachable sets, incorrect collision, missing actions, and capped motion change outcomes.

1. Generate the balance sheet from executable definitions. Current enemy HP uses `1 + 0.09 × stageIndex`, not the stale 0.10 in README/comments. Document rounding and miniboss act multipliers.
2. Calculate actual attack-cycle damage and recovery for each persona/weapon/rarity. Include the three-hit combo, misses, projectile travel/pierce, cancel rules, skill cooldown, swap windows, and realistic uptime. Avoid a single “starter DPS” number representing every build.
3. Enumerate legal item combinations at each proposed slot count. Evaluate damage, effective HP, healing per encounter, cooldown floor, speed/jump reachability, and defensive uptime. Flag runaway loops and items whose benefit is erased by a cap.
4. Compare representative weak/median/strong legal builds against each stage's real enemy population and hazard demand. Analyze trash time-to-kill, miniboss/boss exposure windows, damage opportunities, health recovery, and total encounter time separately.
5. Preserve useful rarity increases without making an unupgraded fresh profile unable to finish. Avoid requiring intentional death solely to access a basic build system. Make bad draft luck survivable through understandable choices and skills.
6. Revisit item descriptions that promise resistance or sustain. Verify the exact effect before tuning it. Simulate set acquisition probability from actual offers/replacement rules; a listed bonus has no balance value if practically impossible to assemble.
7. Collect failed attempts and abandonment as well as successful clears. Initial targets can include the existing uncoached first-three-stage goal of about 15 minutes, but do not claim targets were met until human/device tests establish them.
8. Tune one family at a time with recorded before/after definitions and traces. Avoid simultaneously increasing enemy HP, enemy count, hazard coverage, and decreasing telegraph time; the cause of a difficulty jump must remain understandable.

**Balance deliverables:** generated per-stage/per-build tables; all effect handlers mapped; reachable set/loadout proofs; representative combat traces; target-versus-observed playtest notes; a short list of intentional asymmetries and remaining tuning questions.

## W8 — improve sprites/visuals, animation, UI, and options feasibly

1. Keep the existing procedural style as a valid initial art direction. Inspect all enemy/persona silhouettes at actual camera distance before replacing assets. Imported meshes are not a prerequisite for readable gameplay.
2. Create a visual matrix for all personas, weapon families, enemy shapes, bosses, hazards, pickups, props, and stage palettes. Record silhouette, scale/baseline, facing, animation hooks, hit volume, telegraph color/pattern, and fallback.
3. Prioritize the player, common crab, first miniboss, gator, Steve, turtle, and Spillfather. Give each a clear anticipation/contact/recovery pose; align feet/root with ground and keep hitbox identity visible. Then apply the same quality bar to the rest.
4. Make equipped weapons distinguishable in silhouette/effect, with shared families where appropriate. Do not pretend 28 VFX strings equal 28 authored motions. Use a deliberate fallback for unsupported variants and show only truthful descriptions.
5. Cache rig references once per character. Make same-persona updates idempotent so attack/state acknowledgements do not destroy active tracks. Select fallback per clip based on successful loading, not solely on whether Attack1 has an ID. Resolve default Animate versus custom tracks/procedural poses explicitly and use intentional locomotion/action priorities. Verify empty, partial, denied and complete registries, R15 and any supported alternate rig; reject or fallback for incompatible assets instead of producing a broken pose.
6. Define imported model contracts: PrimaryPart/root, orientation, collision policy, dimensions, rig names, allowed embedded instances, effect attachment names, and required animations. Syntax validation of an asset ID is not a load/permission check.
7. Make assets reproducible in a clean build with an explicit manifest. Avoid Studio-only assets disappearing on Rojo rebuild. Test missing/denied assets and preserve the procedural fallback.
8. Make UI responsive with scale/clamped sizes, text wrapping, scrolling only when needed, safe-area handling, and controller focus/activation. Repair the boss bar and cooldowns before cosmetic restyling.
9. Options should include the useful current visual controls, readable text speed/size, reduced motion, and clear input-specific hints. Remove all sound toggles. Add rebind/support only if the chosen input contract can implement it consistently.
10. Reduced motion must cover camera focus/shake, screen/credit motion, flashes, ambient particles, and combat VFX without changing timing/damage. Colorblind support should rely on patterns/shapes/labels as well as color and should be per viewer.
11. Capture representative screenshots at hub, first fight, midgate, turtle rescue, facility hazard, boss phases, item replacement, options, and small popup states. Check obstruction, contrast, smallest text, and visual timing. No screenshot was captured by the audit itself.
12. Produce experience icon/thumbnail only after the actual slice is stable enough to represent honestly. Use the real visual direction; avoid advertising unavailable assets/mechanics. No trailer/audio production is required for this plan.

**Done when:** the core cast and actions are readable at gameplay scale; fallback/custom asset contracts hold; UI fits tested screens and controller navigation; options affect presentation only; all necessary text remains small and the experience remains silent.

## W9 — performance, analytics, and release ownership

1. Add bounded instrumentation for simulation time, enemy/hazard counts, pending callbacks, alive/pooled instances, connections, profile queue size, remote request/response rates, and allocation/memory trends.
2. Measure representative hub, stage 1, turtle stage, facility mix, and final boss states on target devices. Use profiler captures and percentiles; do not infer FPS from code style or Part count alone.
3. Replace repeated full-world hazard scans with a registry of active hazards and spatial/encounter queries. Avoid traversing pooled/irrelevant folders. Update persona appearance and stable attributes only when their underlying state changes.
4. Cache character/enemy/UI references safely by generation, remove unnecessary hot-loop tables, reduce broadcast audience, and pool only objects whose reuse/reset contract is proven. Do not optimize a broken pool by raising its cap.
5. Set proposed performance budgets per target device and verify them: stable frame-time target, bounded late-game particle/telegraph count, acceptable replication volume, and no unbounded memory/connection growth over repeated runs. Choose actual numeric limits after measuring the repaired slice.
6. Split funnel event semantics from the Roblox provider adapter. Define fields for stage/session, elapsed time, success/failure reason, and device cohort using supported provider mechanisms. Validate fields with a fake adapter, then check actual provider delivery.
7. Emit FTUE failures for timeout/abandon, not only late success. Reset softlock timers on death/transition/close. Distinguish account-first-time, session-first-time, per-run, and per-stage events; publish denominators with success rates.
8. Capture errors visibly and at a bounded rate. A successful `pcall` wrapper with ignored failures is not telemetry evidence. Provider failures must not pause combat or erase dirty progression.
9. Replace the old scorecards with a release evidence table per revision: compiler/type tests, targeted domain tests, Rojo package, engine smoke, full campaign, profile migration/rejoin, two-player configuration/session proof, device screenshots/profiling, and no-audio verification.
10. Verify deployed player limit, avatar rig/configuration, asset availability, API access, build revision, and rollback artifact. Keep release-critical settings in reviewed configuration where possible, and document unavoidable Creator Hub settings with verified evidence.
11. Preserve an immutable build and previous-known-good rollback path. Data migration must remain backward-safe or have a deliberate rollback strategy. Do not publish while any release-blocking acceptance item remains unknown.

**Done when:** runtime resource usage is measured and bounded for the intended audience; metrics retain their meaning; a build cannot claim release readiness on grep checks; deployment facts and rollback are reviewable.

## W10 — required edge-case acceptance matrix

| Area | Required scenarios | Expected invariant |
|---|---|---|
| Boot/readiness | Fresh join; slow Shared/client/profile; missing optional asset; existing character; leave during load | Coherent readiness or explicit recoverable failure; no hidden half-initialized state |
| Input | Each verb on keyboard, controller, touch; text focused; popup/options; held buttons; device change | Same accepted action rules and clear hints; no inaccessible essential verb |
| Movement | 30/60/120 Hz; long frame; coyote/buffer; jump release; reversal; speed/status combinations | Stable movement; no phantom support or frame-rate-dependent gameplay |
| Camera | Start/end of every stage; large X; reverse; arena lock; focus; death/teleport; missing character | Player stays visible; old focus/velocity cannot leak into a new stage |
| Combat | Whiff/hit/kill; multiple targets; zero-health target; ally; behind wall/overhead; projectile tunneling | Visible and actual hit volumes agree; effects/rewards occur only on valid hits |
| Timing | Before/on/after recovery and cancel boundaries; latency; queued attacks; repeated remotes | One authoritative timeline; no duplicate grant or impossible animation cue |
| Enemy state | Flinch/root during windup; hyperarmor; both phase thresholds; lethal threshold; death during summon | Cancel/continue behavior follows explicit rules; no immortal dead enemy |
| Encounter | Zero capacity; overlapping triggers; summoners; boss adds; enemy outside room; cleared wave | Bounded demand and correct encounter completion |
| Hazards | Enter/exit edges; long volume center vs edge; overlapping types; immunity/resist; pads/wind/conveyor | Actual registered geometry/effect, deterministic stacking, no competing motion writer |
| Recovery | Fall while airborne checkpoint candidate; repeated fall; water timeout; moving platform; gate edge | Return to supported safe space without progress bypass or infinite falling |
| Draft | Unoffered valid ID; invalid/stale offer; full capacity; replacement; duplicate click; next-stage race | Exactly one authorized choice and recoverable UI |
| Loadout/economy | Every persona; active/equipped smash; insufficient funds; each rarity; upgrade/rejoin | Legal selection and atomic persistent cost/benefit |
| Saves | Failed read then successful write; v1/v2 mismatch; concurrent mutation/save; unload in flight; retries; old server | Never overwrite unknown/newer state; final accepted mutation survives |
| Session | Two joins, start/finish/death/rescue simultaneously; leave/rejoin; old callbacks | Enforced single-player restriction or correct party/session isolation |
| Story | All acts; early death; fast transition; consecutive required lines; long/Unicode text | No missing necessary connection, stale line, forced large panel, or combat blockade |
| Finale | Boss-first; turtle-first; simultaneous final kill/rescue; duplicate finish callbacks; early dismissal | Shared boss-and-rescue predicate; exactly one reward/completion and truthful cumulative counts |
| No audio | Fresh/old settings; all verbs/stages; UI; respawn; credits; default avatar sounds | No experience-owned or character sound playback |
| UI/accessibility | Narrow/wide, portrait/landscape, safe areas, large text, gamepad focus, reduced motion, colorblind | Legible compact conversations; usable controls; same simulation results |
| Resource lifetime | 20-stage campaign; repeated deaths/runs; delayed tasks; pooled reuse; player churn | Counts return to expected baselines; no retained destroyed objects or runaway work |
| Metrics | Success, timeout, abandonment, repeated run, death in room, provider error | Correct denominators/scopes and retained dimensions; simulation unaffected |
| Release | Clean checkout/build; configured capacity/rig; restricted asset load; profile migrate; rollback | Reproducible artifact and reviewable evidence for the exact revision |

Do not repeat the entire matrix after every tiny change. Run targeted tests as contracts change, then one complete campaign/device/soak pass for the release candidate. Repeat affected cases when a failure or later change invalidates the earlier evidence.

## Milestones and stop conditions

**Milestone A — trustworthy foundation:** W0, W1, W2 and the session/lifecycle core of W3. Compile/boot pass, no audio, safe profiles, no unidentified world owner, and compact necessary text. Stop adding gameplay content until this is achieved.

**Milestone B — complete first-three-stage slice:** W4 plus the necessary W5/W6 changes. All device controls work, camera is stable, boss cleanup works, real drafts/loadout selection function, and required story text never disables defense. Capture engine/device evidence.

**Milestone C — coherent campaign:** W5–W7 across every stage and catalog. All sets/rewards/effects are reachable, stage routes and objectives are valid, progression survives rejoin, and the ending is truthful. Tune power only after these corrections.

**Milestone D — release candidate:** W8–W10. Visual/layout/device evidence, bounded resource use, meaningful telemetry, clean build, controlled deployment settings, save migration, no-audio verification, and rollback readiness.

Defer until after these milestones: extra personas/weapons/enemies, branching campaigns, daily modes, monetization, elaborate procedural generation, large custom mesh replacement, and any new external provider. These can add value later, but they would multiply today's unverified combinations. Audio remains excluded entirely.

Every closed finding should have: the corrected owner/contract, the final source change, a meaningful passing check or recorded playtest, and a link from the audit ID. If something remains engine-, asset-, or deployment-dependent, keep it explicitly open. The result should be a stronger game and a release process that can prove it.
