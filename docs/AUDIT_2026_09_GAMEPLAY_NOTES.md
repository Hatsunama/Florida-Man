# Gameplay, movement, combat, enemy, and hazard audit — September 2026

This is the gameplay workstream of the full audit requested on September 4, 2026. Source reviewed: `AttackService`, `CombatService`, `CombatFacade`, `SkillService`, `SwapService`, `EnemyService`, relevant `EnemyFactory` paths, `HazardService`, `MovementController`, `InputController`, `MobileControls`, and their call sites/catalogs. This is a read-only source review plus deterministic arithmetic checks, not a Roblox Studio playtest. No source fixes or asset changes were made in this workstream.

**Release conclusion: do not accept the earlier “shippable” designation.** The source contains a parser blocker and an undefined boss-phase function, plus serious touch-input, movement, combat-volume, lifecycle, and encounter-budget defects. The fact that a feature's identifiers occur in source does not establish that the feature works. Engine-dependent risks below are explicitly identified.

**Product constraint:** no audio anywhere. All necessary conversations must use small popup text. The gameplay fixes and verification plan below assume silent visual cues, readable text, and visible cooldown/status feedback; no fix requires sounds or spoken dialogue.

Priority: **P0** prevents normal execution; **P1** can block progress or substantially break a core mechanic; **P2** is a meaningful correctness, fairness, maintainability, or performance issue; **P3** is bounded cleanup. “Static-proven” means the implementation contradicts the stated behavior or fails a demonstrated code path, not that it was reproduced in a live engine.

## Findings

### GP-01 — P0 — Reserved identifier prevents HazardService parsing

- **Evidence:** `src/server/HazardService.lua:131` and `:139` declare `local until = ...`; `:133-142` use that identifier. `until` is a reserved Lua/Luau keyword. `src/server/GameService.lua:19` requires this module during startup.
- **Scenario / impact:** requiring GameService cannot successfully load the hazard dependency. Normal server setup is blocked before the hazard branches need to run. This is not a rare water-contact edge case.
- **Confidence:** confirmed by the official Luau 0.737 compiler; see [compiler evidence](audit-evidence-2026-09-04/compiler.json). Forty-seven files compile; this module fails.
- **Owner / fix:** gameplay hazard owner renames the variable to `slowExpiry`; build/release owner compiles every Luau file rather than accepting grep-only checks.
- **Acceptance:** all modules parse; startup requires GameService successfully; execute both water and oil branches in a server fixture. A source grep finding the string `OilSlowUntil` must never count as execution evidence.

### GP-02 — P1 — Undefined boss-phase call can leave an immortal dead gate blocker

- **Evidence:** `src/server/EnemyService.lua:275` and `:280` call `EnemyService.UpdateSpillfatherSlickRing`, which has no definition in `src`. The call executes for **every boss or miniboss**, after HP is reduced at `:244` and before death cleanup at `:285-286`. Further damage returns early at `:234` when HP is zero. `CountHostile` at `:358` counts registry membership, not positive HP.
- **Scenario / impact:** first 66% or 33% threshold crossing errors. If that threshold-crossing hit is lethal, `_Poof` never runs, no kill/drop callback fires, and the zero-HP model remains a hostile that gates wait to disappear. Crab King is affected; this is not confined to the finale.
- **Confidence:** static-proven missing function and control-flow consequence.
- **Owner / fix:** combat owns HP/death and emits a typed phase event; boss encounter/hazard owner consumes the event for Spillfather only. Ensure death cleanup cannot be skipped by an optional visual/hazard callback. Compute phase from remaining HP so a hit crossing two thresholds chooses the correct phase directly.
- **Acceptance:** one-shot and incremental kills of every boss/miniboss; simultaneous threshold crossings; each kill emits exactly one reward/removal; no living-registry entry has zero HP.

### GP-03 — P1 — Touch players cannot use the custom movement/jump loop and have no swap button

- **Evidence:** `src/client/Controllers/MovementController.lua:112-115` disables default walking and both jump parameters. Its movement input at `:329-347` reads keyboard and Gamepad1 only. Jump begins only from Space/ButtonA at `:254-257`. No touch stick, `Humanoid.MoveDirection`, PlayerModule control vector, or `JumpRequest` feeds the custom mover. `src/client/UI/MobileControls.lua:51-77` offers ATK/SKILL/DASH/USE/WPN, but no movement, jump, or swap.
- **Scenario / impact:** on a touch-only device the default Roblox controls cannot drive the velocity-based mover. The player cannot traverse the level or perform normal jumping; dual-persona play also lacks touch access.
- **Confidence:** static-proven input paths missing; physical device verification remains required after implementation.
- **Owner / fix:** one input-action adapter maps keyboard, gamepad, and touch to movement/jump/attack/skill/swap/dodge/interact commands. Keep movement physics outside UI button implementations.
- **Acceptance:** a fresh mobile user can independently move both directions, hold/release jump, dodge, attack, use skill, swap, select weapon, rescue, and finish stages 1–3. Test device rotation and input-mode changes.

### GP-04 — P1 — Skill direction uses stale run-state facing

- **Evidence:** `src/server/SkillService.lua:40` uses `s.facing`. `AttackService.lua:95-98` refreshes it from the character when attacking; `SwapService.lua:25-26` refreshes it on dodge. Ordinary direction changes in `MovementController.lua:374-375` never update authoritative run-state facing.
- **Scenario / impact:** move left and immediately use Bonfire Shuffle, Swamp Exhale, Royal Pinch, or Cartwheel Drive-By without attacking/dodging first. The skill can fire or teleport right while the character faces left.
- **Confidence:** static-proven stale data source.
- **Owner / fix:** combat command validation reads one authoritative facing snapshot from the character/movement state, or accepts a finite signed intent reconciled against that state. Do not make skill direction depend on the last different action.
- **Acceptance:** all directional skills follow current facing after idle turns, airborne turns, stage teleports, and persona swaps.

### GP-05 — P1 — Dash skills teleport through collision barriers and miss their own starting path

- **Evidence:** `src/server/SkillService.lua:118` adds 14/16 studs directly to `hrp.CFrame`, without sweep, barrier check, or stage clamp. Damage is evaluated only within 12 X studs of the **endpoint** at `:124`, without Y/Z restrictions.
- **Scenario / impact:** a player adjacent to a locked thin gate can teleport to its far side. A foe directly beside the start position can be skipped because it is more than 12 studs from the destination, while a distant vertically separated foe at the endpoint is hit. Golf Cart's “multi-hit scrape” in `Personas.lua:103` is a single endpoint pass.
- **Confidence:** static-proven collision/query omissions; exact gate bypass should be recorded in Studio.
- **Owner / fix:** movement authority resolves a swept capsule/box against stage barriers, returning the actual traveled segment. Combat sweeps the corresponding attack volume with explicit per-target hit limits. UI reads the accepted trajectory.
- **Acceptance:** test dash into MidGate, rear barrier, stage bounds, gap edge, enemy at start/middle/end, and elevated enemy. Document whether cart is one hit or repeated hits and make copy agree.

### GP-06 — P1 — Enemy damage exceeds the visible telegraph and ignores player height

- **Evidence:** `src/server/EnemyService.lua:743-744` uses `max(zone.Size.X, zone.Size.Z) * 0.55` for X reach and only a global Z-lane check. There is no Y bound. SelfieZombie's primary zone at `:656` is 6.05 studs wide in X and 12 in Z, yielding a damage half-width of 6.6 versus visible X half-width 3.025. Damage reaches **3.575 studs beyond each visible X edge**. Other attack zones are similarly inconsistent.
- **Scenario / impact:** the player visibly leaves a warning rectangle or jumps well above a ground attack and still takes damage. This undermines readable dodging and makes ground-jump teaching inconsistent with enemy attacks.
- **Confidence:** static-proven geometry; numeric example calculated directly from source dimensions.
- **Owner / fix:** combat geometry owns typed hit volumes with X/Y/Z extents and explicit ground-only/aerial behavior. Telegraph rendering consumes that same volume. Decorative secondary indicators must not accidentally become damage areas.
- **Acceptance:** sample just inside/outside each boundary, both facing directions, standing/jumping/elevated positions, all enemy telegraph variants, and colorblind mode. Record zero unexplained hits outside the displayed danger region.

### GP-07 — P1 — Enemy oil puddles are visual props, not hazards

- **Evidence:** `src/server/EnemyService.lua:380-391` creates a part named `OilSlick`, but sets no `Hazard` attribute. `src/server/HazardService.lua:124-125` only handles hazard parts tagged by that attribute. The puddle branch runs for OilGator, all `puddle` enemies, and phase-3 Spillfather at `EnemyService.lua:726-731`.
- **Scenario / impact:** Oil Puddle Layer promises slowing slicks, but its puddles never slow, damage, or otherwise interact. Slushie, red tide, oil, and boss “hazard” identities collapse to decorative patches.
- **Confidence:** static-proven producer/consumer contract mismatch.
- **Owner / fix:** EnemyService requests a typed hazard spawn from HazardService; that service owns hazard kind, lifetime, overlap, and resistance rules. Visual appearance remains in a renderer/factory.
- **Acceptance:** spawn every puddle-emitting enemy; step into the resulting puddle and verify the documented effect, expiration, resistance, no-audio cue, and cleanup on stage change.

### GP-08 — P1 — Soft checkpoints record air rather than verified safe ground

- **Evidence:** `src/server/HazardService.lua:249-251` stores `LastSolidX/Y` for any position with `1.5 <= Y < 40`. No ground query or collision support is required. `triggerSoftFall` uses those values at `:36-44`, superseding the stage checkpoint.
- **Scenario / impact:** run/jump over a gap and fail. The last “solid” coordinate can be midair above the gap, so recovery returns the player to another fall. It also advances checkpoints from airborne travel rather than verified route progress.
- **Confidence:** static-proven incorrect safety criterion; repeated-fall severity depends on layout and input timing.
- **Owner / fix:** movement/hazard authority records last safe grounded support using collision-filtered floor queries and a safe standing transform, rejects hazardous/non-support geometry, and resets that record on stage/run change.
- **Acceptance:** walk-off, failed jump, missed pad, wind fall, dash into void, and prolonged gap contact all return to stable reachable ground without recovery loops.

### GP-09 — P1 — Server hazard impulses fight a client-owned velocity loop

- **Evidence:** `src/server/HazardService.lua:163-165` changes X velocity for conveyors; `:185-194` replaces wind velocity. `src/client/Controllers/MovementController.lua:387-388` overwrites X with its private `velX` every render frame. GameService deliberately gives character network ownership to the player at `:103`, `:109`, and `:117`.
- **Scenario / impact:** conveyor and wind effects can be overwritten on the next client frame or appear as jitter. Their sustained displacement is not integrated into the mover that owns velocity, making two major late-stage verbs unreliable.
- **Confidence:** competing writers are static-proven; exact replication/jitter behavior requires Studio latency tests.
- **Owner / fix:** server owns accepted environmental forces/status and collision policy; the movement integrator consumes those forces in the same simulation step as input. Client predicts that approved state. Avoid arbitrary competing writes from a 20 Hz scan and a variable-rate render callback.
- **Acceptance:** left/right/idle/jumping/dodging on every conveyor and wind zone at 30/60/120 FPS and representative latency produces the designed displacement consistently.

### GP-10 — P1 — Encounter caps are advisory; waves and summons can exceed them indefinitely

- **Evidence:** `src/server/StageFlowService.lua:427` uses `math.max(1, room)` even when available room is zero. MidGate's equivalent is `:511`. Boss creation at `:452-455` adds four enemies without reservation. `src/server/EnemyService.lua:377` spawns summons without a cap; phase-3 Spillfather creates two per attack at `:720-723`. `Balance.MaxHostiles` promises 2/3/4 enemies.
- **Scenario / impact:** progress triggers overfill already occupied encounters; surviving summoners repeatedly create more enemies. This breaks density/readability promises and raises CPU, replication, hitstop, and difficulty beyond the documented balance model.
- **Confidence:** static-proven bypass; exact line anchors should be checked if StageFlow changes during audit integration.
- **Owner / fix:** one encounter-spawn owner reserves capacity for waves, minibosses, bosses, adds, and summons. Queue unspawned members rather than marking a full wave consumed. Define separate and explicit boss add budgets if necessary.
- **Acceptance:** simultaneous progress thresholds, full room, two summoners, prolonged boss survival, and retry flows never exceed the configured encounter cap or silently discard required enemies.

### GP-11 — P1 — Delayed combat work survives run/stage ownership changes

- **Evidence:** `src/server/CombatService.lua:320-379` and `:409-435` own independent Heartbeat callbacks and Workspace-level parts. They do not verify attacker still exists, current run identity, stage identity, or `runActive`. `AttackService.lua:119-149` and `SkillService.lua:42-44` close over mutable/captured run state. `EnemyService.Clear` only clears enemy membership. Enemy telegraphs use model identity but no spawn generation at `EnemyService.lua:707-717`.
- **Scenario / impact:** a lingering coil/projectile can remain active through death/quick restart or hit a newly loaded enemy. A pooled model reused during a prior telegraph can satisfy `_alive[model]` again and allow an old attack to complete against a new spawn. Old callbacks can award drops using current state while applying damage modifiers from a prior state.
- **Confidence:** missing ownership/cancellation is static-proven; fastest overlapping transition/spawn cases require timed fixtures.
- **Owner / fix:** introduce run ID, stage/encounter ID, and spawn generation. All scheduled work must carry and validate these identities, and be canceled on owner teardown. Effects should belong to an owned stage-effect container.
- **Acceptance:** change stage, die/restart, disconnect attacker, remove target, kill/reuse model, and clear arena during an active projectile/coil/telegraph. No old task may damage, reward, summon, clear a newer status, or display obsolete feedback.

### GP-12 — P1 — Accessibility setting changes actual physics; hitstop depends on frame rate

- **Evidence:** `src/client/Controllers/MovementController.lua:191-194` suppresses Hitstop entirely under ReduceMotion. When active, `:306-309` zeros X and multiplies current Y velocity by 0.35 on **each RenderStepped**, rather than once or proportionally to elapsed time. `EnemyService.lua:252` broadcasts hitConnect to all clients; `init.client.lua:159` applies it to each local mover.
- **Scenario / impact:** ReduceMotion users retain movement/jump progress that other users lose. A 0.06-second hitstop at about 30 versus 120 FPS applies about 2 versus 7 vertical multiplications: remaining upward speed factors are approximately 0.1225 versus 0.000643 before gravity. Other players' attacks can interrupt your movement if multiplayer is allowed.
- **Confidence:** static-proven gameplay/presentation policy coupling; frame count varies with scheduling, so numbers are illustrative formula checks.
- **Owner / fix:** combat decides any intentional simulation freeze; accessibility only adjusts camera, poses, particles, and screen motion. Prefer visual hit-pause without modifying player movement; if movement pause is a designed mechanic, make it deterministic, time-based, and scoped to the attacker.
- **Acceptance:** equivalent input produces equivalent displacement and jump reach with ReduceMotion on/off, at several FPS, and while another player attacks.

### GP-13 — P2 — Cancel windows are HUD decoration, not a governed combat mechanic

- **Evidence:** `src/server/CombatService.lua:135-163` stores cancel timestamps. `AttackService.lua:193-201` checks them only to send `cancelWindow`. Repository references do not show any action authorization using `InCancelWindow`. Skill and swap only check their own cooldowns; `CanAttack` waits for full attack recovery.
- **Scenario / impact:** “CANCEL” flashes without defining any newly legal action. Skill/swap/dodge can already start outside the window, while the next attack still cannot. The UI promises a timing skill the runtime does not implement.
- **Confidence:** static-proven missing rule consumer. N6 correctly added timestamps and a flash, but its combat-depth claim is overstated.
- **Owner / fix:** define a finite combat action state with recovery, permitted cancel targets, minimum cancel time, and what happens to combo progression. Alternatively remove the cancel language until an actual mechanic exists.
- **Acceptance:** action table tests at just before/at/after open and recovery times for attack→attack/skill/swap/dodge; client cues correspond to accepted commands and rejected commands have clear visual correction.

### GP-14 — P2 — Flinch and net root do not interrupt an attack already telegraphing

- **Evidence:** `src/server/EnemyService.lua:443-445` handles telegraphing before reading flinch/root at `:448-455`. The waiting attack at `:707-717` checks existence/membership only, never flinch/root. `AttackService.lua:34-35` applies net root.
- **Scenario / impact:** a netted/staggered non-armored enemy finishes its attack uninterrupted. The visual flash/root and the advertised interrupt/stun expectations can conflict. A foe knocked away during its telegraph still attacks the original marker positions.
- **Confidence:** static-proven. Whether specific attacks should resist interruption is a design decision that must be explicit, not an accidental ordering consequence.
- **Owner / fix:** enemy action state defines interruptibility, cancel token, and telegraph anchoring. Apply root only to movement if that is intended and state it in item text; distinguish root from stun and hyperarmor visually.
- **Acceptance:** hit/net during idle, windup, active, recovery, and hyperarmor, including knockback after warning creation. Each attack follows its documented interrupt rules.

### GP-15 — P2 — Anchored knockback permanently levitates most enemy types

- **Evidence:** `src/server/CombatService.lua:244-246` adds 0.25/0.6 Y per hit for anchored roots. `EnemyFactory.Build` at `src/server/EnemyFactory.lua:1168` anchors the root. Most EnemyService movement branches preserve `root.Position.Y`; only hopper explicitly derives a base Y. Attack distance uses 3D distance at `EnemyService.lua:467`.
- **Scenario / impact:** repeated hits lift grounded foes higher and higher. Once vertical separation exceeds attack range, X-only chasing cannot reduce it, making foes float/inert. Player melee can still hit them because its query omits Y.
- **Confidence:** static-proven positional accumulation; visible displacement should be filmed after a fixable execution build exists.
- **Owner / fix:** store floor/support baseline, apply bounded transient displacement with a return curve or use proper physical knockback, and keep gameplay attack range consistent with the chosen movement model.
- **Acceptance:** 50 weak/heavy hits on each non-hopper archetype keep it grounded or return it predictably, without embedding in barriers or becoming unreachable.

### GP-16 — P2 — Enemy pool teardown retains dead references and disables reuse

- **Evidence:** pools are placed beneath GameWorld by `src/server/EnemyService.lua:31-44`. `EnemyService.Clear` parks enemies there at `:111`, and `StageFlowService.LoadStage` immediately calls `WorldBuilder.BuildStage`. `src/server/WorldBuilder.lua:155` clears every GameWorld child. `enemyPool` is not cleared or compacted; Spawn's search at `EnemyService.lua:142-149` skips destroyed models but leaves them occupying the array and its capacity. `lastAttack`, `chargeDir`, and `burrowCD` at `:367-370` also retain model keys without removal.
- **Scenario / impact:** pooled models are destroyed at stage transition but their references continue counting against POOL_MAX_ENEMIES. Reuse performance collapses while per-enemy AI bookkeeping grows over a long session.
- **Confidence:** static-proven lifecycle mismatch. Separately, reviving a Humanoid after zero HP and default joint-death behavior needs an engine test; do not assume changing Health alone reconstructs a dead rig.
- **Owner / fix:** either remove this optimization until measured or give pools a lifecycle outside the stage subtree, a complete reset contract, generation IDs, and explicit map cleanup. Clear must not anchor Motor6D-driven children permanently if those models can be reused.
- **Acceptance:** 20 stage changes, hundreds of kills/reuses, and repeated restarts maintain bounded table sizes; reused models move/animate/attack correctly and have fresh HP/status/cooldowns.

### GP-17 — P2 — Client decides extra speed/slow policy and suppresses real item bonuses

- **Evidence:** `src/client/Controllers/MovementController.lua:366` caps the server's computed speed to 23. `RunContext.ApplyCharacterSpeed` computes persona speed plus items without that cap at `src/server/RunContext.lua:273-289`. Karen sets server `SlowUntil` using `os.clock` at `EnemyService.lua:751`; the client compares that timestamp against its own independent `os.clock` at `MovementController.lua:319-322` and applies an extra 0.55 multiplier.
- **Scenario / impact:** valid speed builds above 23 lose advertised benefit. Karen's duration can be wrong because client/server clocks are not a shared time base; its slowdown also bypasses the single server speed stacking rule used for oil/hangover.
- **Confidence:** static-proven conflicting policy/clock domains; specific visible duration depends on process clock offsets.
- **Owner / fix:** server status/stat owner computes one movement snapshot, including cap and stacking. Share synchronized server time or send durations plus sequence numbers. Client applies predicted motion from that snapshot without inventing a second balance rule.
- **Acceptance:** all persona/speed-item combinations, Karen plus oil/hangover, expired status, late join, and respawn show the same speed and remaining duration on server and client.

### GP-18 — P2 — Dodge cooldown, movement distance, and visual invulnerability disagree

- **Evidence:** server cooldown uses item CDR at `src/server/SwapService.lua:20`; client hardcodes full `Constants.DODGE_COOLDOWN` at `MovementController.lua:228`. Client assigns 62 X velocity at `:236` but saves `velX = 34.1` at `:237`, which `:388` applies from the next render onward. At 0.18 seconds, steady burst travel is about 6.14 studs, not the unused `Constants.DODGE_DISTANCE = 18`. The client animates and sets IFrameVFX before acceptance; DoDodge can reject without a denial response.
- **Scenario / impact:** dodge CDR items work on the server but ordinary client controls cannot use them. Movement differs from the configured distance and can be frame-timing sensitive. A rejected dodge can look protected while the authoritative iframe has not been granted.
- **Confidence:** static-proven split rules and arithmetic; record exact travel under engine physics.
- **Owner / fix:** one dodge definition owns duration, speed/distance, cooldown, and iframe schedule; predict using request IDs, reconcile accepted timing, and correct rejected effects. Expiry updates must not let an older dodge/swap callback clear a newer active visual.
- **Acceptance:** every CDR item, holding/repeated tapping, airborne dodge, overlapping swap/cart iframes, latency/rejection, and run reset produces consistent movement and truthful protection feedback.

### GP-19 — P2 — Attack prediction cannot support the fastest legal builds reliably

- **Evidence:** `src/client/Controllers/InputController.lua:116` defines fallback recovery 0.22; every swing resets to it at `:146` before the server corrects it. `SyncAttackReady` at `:122-127` applies server remaining duration at receipt without transit adjustment. Server token rate is 8 attacks/sec in `Constants.lua:39`. GolfCartBandit+PoolNoodle recovery permits approximately **10.60 attacks/sec**; SnakeCharmer+PoolNoodle about **8.625/sec**, from the actual three-hit movesets and speed scales.
- **Scenario / impact:** fast builds are clipped by the anti-spam budget, and network delay/fallback buffering reduces reachable attack rate. Optimistic swing VFX still play before server acceptance, so N6's “no client-only god swings” statement is not established by the clock-sync code.
- **Confidence:** static-proven rate-budget contradiction; perceived latency/ghost swing rate requires network simulation.
- **Owner / fix:** use an accepted combat snapshot to predict per-move recovery and a sequence/acknowledgment protocol; derive remote capacity above the maximum lawful cadence with a bounded margin, while damage authority still enforces recovery.
- **Acceptance:** max-speed legal loadouts sustain their designed cadence without token denials at multiple ping values; spam remains harmless; rejected predicted attacks correct pose/combo rather than advancing a ghost combo.

### GP-20 — P2 — Projectile collision samples endpoints, allowing tunneling and unordered pierce

- **Evidence:** `src/server/CombatService.lua:329-330` advances by speed×dt; `:357-359` compares only the new point to enemy root with X radius 3.2. At ranged speed 78, a 0.1-second heartbeat advances 7.8 studs, wider than the 6.4-stud hit interval. Iteration order comes from `EnemyService.GetAlive`, a map-backed array; hit candidates are not ordered along flight. Lifetime/range expiration occurs after the hit loop at `:373`.
- **Scenario / impact:** a hitch can skip a target, hit targets beyond intended max distance, or consume limited pierce on a farther overlapping target before a nearer one. Part visuals also pass through obstacles because no world sweep is performed.
- **Confidence:** static-proven discrete-collision limitation; numerical hitch counterexample follows directly from constants.
- **Owner / fix:** collision subsystem sweeps from previous to next pose, clamps the segment to remaining range, computes contact order, and applies explicit obstacle/pierce policy.
- **Acceptance:** stationary targets at edge positions with dt 1/30, 1/60, 0.1, and 0.2; two/three aligned targets; thrown arcs and blockers; endpoint/max-distance boundary.

### GP-21 — P2 — Melee, beams, dash, and summon disagree about vertical/lane reach

- **Evidence:** `AttackService.lua:163-164` checks X and target Z but no Y or attacker lane. `SkillService.lua:89` checks directional X only for wave/beam; dash at `:124` checks only X. `CombatService.lua:431` for lingering coil checks X/Z only. AOE uses full 3D magnitude at `SkillService.lua:100`.
- **Scenario / impact:** some attacks hit far above/below the visible effect, while others miss the same target. Jumping can remotely hit ground enemies with melee or a beam regardless of height; lane-offset/teleported attackers may still damage lane targets.
- **Confidence:** static-proven volume inconsistency.
- **Owner / fix:** shared authoritative volume/query primitives distinguish capsule, box, radial, cone, and swept-path attacks. Each catalog move declares dimensions and valid targets; renderers mirror those volumes.
- **Acceptance:** a grid of same-X/different-Y/Z targets produces the expected result for every skill/weapon class, including ally exclusion, elevated platforms, and point-blank behind-facing cases.

### GP-22 — P2 — Enemy targeting does not filter active/alive participants

- **Evidence:** `src/server/EnemyService.lua:463-477` considers every player with HumanoidRootPart, without run ownership or Humanoid health; escort selection at `:406-417` has the same issue. Only the later CombatFacade damage callback checks `runActive`.
- **Scenario / impact:** enemies can chase or telegraph at a hub/nonparticipating/dead character while ignoring the real combat participant. Final damage rejection does not repair targeting, enemy positioning, summons, or consumed attack cadence.
- **Confidence:** static-proven missing target eligibility. Full multiplayer scope is audited separately because the world itself is global.
- **Owner / fix:** session/encounter owner supplies eligible combatants; EnemyService chooses targets only within that list. Keep aggro weighting separate from actual geometric distance so taunt weights do not change attack range.
- **Acceptance:** active, dead, spectating, hub, disconnecting, and far-lane characters coexist without stealing combat/escort targeting; aggro changes priority but never range.

### GP-23 — P2 — Ground detection accepts non-support decoration and creates phantom jump opportunities

- **Evidence:** `src/client/Controllers/MovementController.lua:124-128` raycasts with only character exclusion and accepts any hit. It does not use a walkable collision group, `RespectCanCollide`, surface normal, or a dedicated ground tag. Hazard/telegraph/ghost parts are often non-colliding but remain queryable; only projectiles explicitly disable CanQuery at `CombatService.lua:300`.
- **Scenario / impact:** a cosmetic ghost, ground-level non-colliding gap-water marker, or hazard visual can satisfy the grounded ray and refresh coyote time, permitting jumps from non-support surfaces. Avatar-size differences also make the fixed 3.2-stud ray unreliable.
- **Confidence:** missing filter is static-proven; which decorative parts are intersected requires engine/avatar fixtures.
- **Owner / fix:** movement queries a shared walkable/support collision group or tag, uses actual character support dimensions, checks acceptable surface normals, and excludes cosmetic geometry at creation.
- **Acceptance:** jump near dodge ghosts, telegraphs, gap markers, water, enemy bodies, ramps, scaled avatars, and thin platforms; only valid surfaces refresh grounded/coyote state.

### GP-24 — P2 — Popup/UI blocking is inconsistent and can remove combat while danger continues

- **Evidence:** `src/client/Controllers/InputController.lua:28-33` treats Tagline/Options/Credits/Steve as blocking combat input. MovementController polls held keys directly at `:329-330` and only checks its separate `enabled` flag; these popups do not uniformly call SetEnabled. A plain TextBox focus can still produce A/D movement because render polling ignores focused UI. `SetEnabled(false)` at `MovementController.lua:187-188` does not clear velocity or buffers; its render callback simply returns at `:295`. `MobileControls.lua:60-61` fires skill directly rather than through a shared modal-aware dispatcher.
- **Scenario / impact:** a story popup during an encounter blocks attack/skill but leaves movement and enemy attacks active; modal behavior differs by device/action. Existing momentum can keep moving the character when a newspaper/draft disables the controller. Typing may move the character.
- **Confidence:** static-proven inconsistent policy; user-visible timing requires input/UI integration tests.
- **Owner / fix:** one input-focus/modal policy exposes which actions are allowed. Make small story popups nonblocking during combat, or use an explicit server pause/encounter-safe moment. Hard modal entry clears desired movement/jump/action buffers; all mobile/gamepad/keyboard actions pass through the same dispatcher.
- **Acceptance:** open every popup while moving, jumping, attacking, and being targeted; type in chat; close/resume; rotate mobile; overlapping modals never re-enable blocked input early.

### GP-25 — P2 — Hazard geometry is an unrelated radius rather than the visible area

- **Evidence:** `src/server/HazardService.lua:127-128` uses fixed center-distance reaches 4.5/5/6/8 independent of part size; conveyor visuals are 14 studs long at `WorldBuilder.lua:279`, water is 12×8 at `:330`, and large boss slick geometry has a separate layout. JumpPad at `HazardService.lua:198` checks X and an upper Y bound but no lower Y or Z bound. Generic timed activity defaults to true when no period exists (`:58-60`), so the initially faint finale slicks created at `WorldBuilder.lua:643-646` are active immediately.
- **Scenario / impact:** visible hazard edges can be safe or invisible margins harmful; wide water crossing can leave unrecognized regions; pad activation can occur below the pad/off-lane. Finale ring appearance/phase and runtime hazard activation are disconnected.
- **Confidence:** static-proven mismatched bounds and default activity; intended boss-stage rules need a design decision.
- **Owner / fix:** HazardService owns explicit OBB/capsule volumes, active state, timed phase, and jump-pad eligibility. WorldBuilder renders those definitions. Only update visual properties when phase changes, and expose timing with shape/text cues, never audio.
- **Acceptance:** test each hazard at center/edge/corner/above/below, active/inactive transitions, resist/iframe states, overlapping hazards, pad approach from all axes, and each boss phase.

### GP-26 — P2 — Enemy presentation and transient hit effects run on the authoritative hot path

- **Evidence:** `EnemyService.StartAI` runs each Heartbeat and calls `EnemyFactory.Animate`; `EnemyFactory.Animate` traverses descendants and writes Motor6D transforms/AnimPhase every tick. Telegraphing models are animated both in the heartbeat at `EnemyService.lua:444` and the telegraph wait loop at `:714`. `EnemyFactory.HitFlash` at `src/server/EnemyFactory.lua:1283-1296` traverses all parts and creates one delayed callback per part per hit. `RunContext.ApplyCharacterSpeed` is called by the 0.05-second server pump and unconditionally calls ApplyPersonaLook at `:305`.
- **Scenario / impact:** authoritative simulation spends time and replication budget on visual poses, repeated unchanged avatar colors/highlights, and many tiny delayed callbacks. Rapid overlapping flashes can restore an already-flashed white color as the “original”, leaving visual state wrong. Cost grows sharply when GP-10 overfills encounters.
- **Confidence:** work/replication paths are static-proven; measured CPU/network impact is not yet available.
- **Owner / fix:** server owns action/facing/state transitions; clients interpolate visual pose and flash from compact events. Cache rig joints and base colors. Update character presentation only on actual persona/weapon/status changes. Use one flash expiry per model instead of callback-per-part-per-hit.
- **Acceptance:** compare server script time, replication bytes, client frame time, instance count, and retained tasks over representative capped encounters; no permanent white materials after burst hits; animation advances once per intended timestep.

### GP-27 — P2 — Cooldown truth is duplicated and does not reset with the run

- **Evidence:** skill/swap deadlines exist both in RunState and private CombatService tables. `RunContext.NewRunState` at `:193-195` resets visible deadlines to zero. `CombatFacade.KillPlayer` clears iframes/shield at `:38-39` but not attack/skill/swap tables. CombatService clears those only on PlayerRemoving at `:438-446`. Skill consumes cooldown at `SkillService.lua:32-33` before checking HumanoidRootPart at `:34-37`.
- **Scenario / impact:** after death/quick restart the HUD/run state can say an ability is ready while the hidden combat table rejects it. A skill request during character replacement can consume cooldown without performing a skill.
- **Confidence:** static-proven duplicated state and order.
- **Owner / fix:** one run-scoped combat state owns all cooldowns and reset semantics; validate the actor first, then atomically accept the command and commit cooldown. Replicated UI state is derived from that same accepted state.
- **Acceptance:** death, restart, finish/return to hub, character replacement, disconnect, and invalid actor requests maintain exact agreement between HUD and accepted commands.

### GP-28 — P2 — On-hit bonuses run before confirming a valid damaging hit

- **Evidence:** `src/server/AttackService.lua:65-69` applies specials and weapon secondary before EnemyService validates membership/health. Heroic healing occurs at `:57-59` using requested damage before enemy resistance/final applied damage, and before success is known. The local hit counter at `:119-121` increments regardless of ApplyDamage's result. EnemyService's Boolean means killed, not accepted/damaged (`:285-289`).
- **Scenario / impact:** stale/zero-HP targets can trigger apparent hits and healing once the set is made reachable; requested overkill can heal based on damage not actually dealt. Callers cannot distinguish rejected hit from nonlethal hit through the current return value. Ranged `CombatEvent.hit` is calculated before any projectile hit occurs, so it is always false for the initial attack event.
- **Confidence:** static-proven API contract issue. Heroic lifesteal is presently unreachable under the item-slot cap (reported by the catalog/progression audit), so the healing exploit is latent rather than presently reachable through ordinary play.
- **Owner / fix:** a damage transaction returns `{accepted, damageApplied, killed, statusApplied}`; apply permitted post-hit effects only after acceptance and use actual damage. Render contact feedback from confirmed hit events, never scheduled-shot counts.
- **Acceptance:** rejected/dead/ally targets, overkill, shield/armor, multi-target pierce, pooled reuse, and invalid attacker produce correct healing and feedback exactly once.

### GP-29 — P2 — Several advertised archetypes have no corresponding behavior

- **Evidence:** `Enemies.lua` contains tank/spitter identities and narrative attacks. `EnemyService.StartAI` only has bespoke locomotion for charger/burrower/hopper/scuttle; other roles use X-only chase. Spitters do not emit enemy projectiles; they stop at range 16 and perform zone damage. Several zones do not reach the trigger range, creating harmless repeated attacks at certain distances. `SkillService` beam/wave share one X-only loop; shield heals the caster only and does not consume skillDamage for a pulse; cart uses one endpoint hit.
- **Scenario / impact:** names imply ranged shots, stun, ally support, or repeated scraping that the player cannot find in the actual loop. Differences are partly real (timing, movement branches, zone layouts, summons), but the catalog overstates implementation.
- **Confidence:** static-proven missing behavior consumers, with design intent to be resolved against current copy.
- **Owner / fix:** build a behavior matrix defining each enemy's approach, windup, active hit geometry, recovery, interruptibility, and counterplay. Prioritize a small set of distinct working archetypes before adding more names. Either implement the promise or rewrite specific copy.
- **Acceptance:** an observer can name each role's counterplay from a silent encounter; automated scenario tests ensure enemies that choose to attack can actually reach the intended target volume.

### GP-30 — P3 — Unused scaffolding and magic constants obscure the real control model

- **Evidence:** `MovementController.SetHangover` is intentionally empty (`:180`), `jumpHeld` is assigned but never used to control physics (jump cut uses InputEnded directly), `Constants.DODGE_DISTANCE` has no consumer, and moveset/weapon values are mixed with hardcoded client fallback values. `CombatService` contains unused lane helpers while skill branches duplicate their own checks. `HazardCtx.moveSpeed` is copied through the tick pump but hazards do not use it to own movement.
- **Scenario / impact:** reviewers infer mechanisms from names and comments that no longer drive the game. This assisted earlier false-positive acceptance reports.
- **Confidence:** static-proven reference inventory; cleanup should follow the ownership changes, not pre-empt them.
- **Owner / fix:** remove obsolete public APIs/state, document deliberately retained compatibility adapters, centralize tunables used by real gameplay, and type command/state/result structures instead of broad `any` dependencies.
- **Acceptance:** reference scan has no accidental dead APIs; documentation and tests reference only live behavior; no cleanup changes accepted gameplay semantics.

## Responsibility ownership verdict

| Layer / module | Correct responsibility | Current verdict / misplaced responsibility | Desired boundary |
|---|---|---|---|
| Shared catalogs (`Personas`, `Weapons`, `Enemies`, `Constants`, `Balance`) | Data definitions and pure formulas | Mostly appropriate, but client magic caps/fallbacks and spawn bypasses override catalog promises | Typed, validated data; pure attack/hazard geometry and timing definitions |
| GameService | Composition root, validated request dispatch, player lifecycle | Combat token buckets are sensibly server-side; its per-player loop indirectly rebuilds visual appearance and does not establish an encounter scope | Route typed commands to session-owned services; transport/rate limits do not own gameplay acceptance |
| RunContext | Current run storage and narrow state access | Also owns stat composition, persistence calls, client serialization, character presentation, inventory mutation, and speed application | Split run state, stat/status computation, persistence adapter, replication presenter, and avatar presentation adapters |
| CombatFacade | Narrow command facade | Also resets run/meta state and calls StageFlow from KillPlayer; damage/death/persistence/progression are coupled | Combat emits a death outcome; lifecycle owner performs one idempotent reset/transition |
| Attack/Skill/Swap services | Validate and execute accepted gameplay actions | Correctly server-side damage intent, but inconsistent phase/facing/volume rules, duplicate cooldown ownership, business logic keyed on `weapon.vfx`, and unowned delayed effects | Combat state/geometry/damage pipeline owns acceptance; VFX ID never selects damage/root/fire interaction rules |
| CombatService | Authoritative cooldown/iframe/query primitives | Mixes moveset data, authoritative state, visual Part creation/color selection, per-projectile scheduling, and lazy EnemyService dependency | Pure combat model plus owned projectile simulation; renderer handles visual objects |
| EnemyService | Encounter-owned enemy lifecycle, target selection, AI decisions | Global target registry; also handles boss arena mutation, rescue rewards dispatch, hazard creation, colorblind decoration, visual pose updates, and combat feedback | Encounter scope, typed AI actions, HazardService spawn API, presentation events |
| EnemyFactory | Rig/material creation and optional animation metadata | Writes gameplay attrs; also runs visual animation/death/hit effects on server | Factory provides validated rig contract and immutable metadata; clients render presentation; gameplay state remains server-owned |
| HazardService | Hazard overlap/effects, safe floor fallback | Also creates rescue prompts, drives conveyor visual colors/moving geometry, and writes character velocity independently of its movement owner | Own hazard state/volumes and emit accepted force/status; interaction factory creates prompts; renderer displays phase |
| MovementController | Device-independent predicted movement and animation coordination | Owns hidden speed cap, slow multiplier/time comparison, full dodge cooldown, actual physics hitstop, and raw input polling | Client integrates server-approved movement/status definition; InputAdapter feeds intent; presentation/accessibility does not alter combat truth |
| InputController / MobileControls | Input mapping and local focus policy | Competing modal checks; direct remote bypasses; mobile actions incomplete; local predictions lack acceptance IDs | One command dispatcher + focus service, complete per-device bindings, prediction/acknowledgment |
| HUD/Tagline/options | Small popup text and derived display | Modal existence participates in action permission; ReduceMotion changes physics through mover | Display canonical status and accepted cooldowns; silent presentation choices only |

The security improvement from earlier work is real in one important respect: `CombatService.HasIFrames` reads private server memory, and damage is routed through a server callback to CombatFacade. A client-written IFrameVFX attribute is not currently the authoritative invulnerability decision. Do not repeat the old client-attribute godmode finding as if it were still present. The remaining movement-authority/phase/session weaknesses are separate issues.

Provider/auth/entitlement/memory-policy systems are not part of this game’s combat subsystem. No such providers were found here; do not invent concerns in those categories. Remote command eligibility, run ownership, cooldown truth, encounter access, and release-critical transitions are the relevant equivalents and do require server ownership.

## Reassessment of previous audit coverage

| Prior statement / area | Current status |
|---|---|
| `AUDIT_N8.md` calls the code pack shippable | Rejected by GP-01/02; actual Luau compile and boss kill paths are prerequisite evidence |
| `AUDIT_LAYERS.md` marks enemy/telegraph pooling PASS | Pool existence is true; lifetime/reset correctness is not (GP-11/16) |
| `AUDIT_N6.md` says no client-only swings during recovery | Server damage gating exists, but optimistic visuals and fallback/network timing still disagree (GP-19) |
| N6 cancel windows PASS | Timestamp/flash implemented; governed cancel behavior absent (GP-13) |
| N6 flinch/net PASS | Idle movement gating exists; windup interruption does not (GP-14) |
| N5 conveyor/wind/water verbs PASS | Attributes and branches exist; parser blocker, competing velocity writers, unsafe checkpoint and geometry bugs prevent a functional PASS |
| N3/6 GREASY and HEROIC “fire” | Functions exist; three-piece set reachability must be resolved by progression audit before ordinary-play claims |
| N0/1 mobile attack parity | ATK now uses local prediction, but movement/jump/swap and consistent modal routing remain incomplete |
| N2 private-memory iframe/damage boundary | Current source supports this fix; retained as a positive finding |
| Skill/swap/dodge lack explicit awaitingDraft test | Not independently reported as an exploit: current FinishStage sets runActive=false before newspaper/draft, and these handlers reject inactive runs. Consolidate phase guards for maintainability, but do not confuse defensive consistency with a proven active bypass |
| N5 finale turtle gate “still required” | Must be rechecked in main progression audit: `OnEnemyKilled(Spillfather)` calls FinishRun directly, outside FinishStage's turtle guard |
| Audio described as optional combat/UI SFX | Superseded by the user's current stricter no-audio requirement; passing dialogue-only silence is insufficient |

The strongest missed areas were lifecycle identity, actual parser execution, touch traversal, geometry shared by visuals/hits, movement-force ownership, legitimate maximum-rate inputs, and stateful pool/reset tests. These are not asset-polish questions and should precede another grading exercise.

## Implementation plan and release evidence

1. **Make the current source executable.** Fix GP-01 and missing phase callback; run a real compiler on every module and fail the build on errors. Add a server smoke fixture that requires the service graph, spawns each boss/miniboss, crosses both thresholds, and kills each once. Do not accept textual invariant greps as a substitute.
2. **Establish explicit ownership of a run and encounter.** Decide single-player-per-server versus shared-session multiplayer in the main architecture plan. Add run/stage/spawn generations, task cancellation, one teardown path, one eligible-participant list, and one source of combat cooldown truth. Fix GP-11/16/22/27 before adding more effects.
3. **Unify input and focus behavior.** Complete touch controls and SWAP; centralize command routing; separate small nonblocking story popups from true modal selections. Clear movement/buffer state on hard modal/respawn/teleport. Exercise keyboard/gamepad/touch and focused chat.
4. **Unify movement definition and simulation.** Define canonical speed cap, dodge trajectory/cooldown, grounded test, safe checkpoint, external force integration, and clock domain. Remove ReduceMotion physics differences. Validate jumps/dodges/pads/conveyors/wind under frame-rate and latency variation before tuning level gaps.
5. **Unify combat geometry and action rules.** Define hit volumes, facing snapshot, dash sweep, projectile sweep/order, root/stun/armor semantics, cancel matrix, and accepted damage result. Derive warning visuals and cooldown cues from these rules. Implement no sound dependency.
6. **Make enemy/hazard identities real.** Fix emitted puddles and phase-controlled boss ring; enforce one spawn budget; separate target priority from distance; give each priority archetype distinct counterplay. Align every skill/item/weapon/enemy description to observed behavior. Keep any deferred mechanics explicitly deferred.
7. **Recalculate balance from attainable builds.** Use the main audit's resolved slot/loadout/unlock rules. Measure legal attack cadence, damage applied, range utility, incoming DPS, and active iframe duty rather than comparing catalog damage alone. Tune fast-build token capacity and telegraph/attack timings only after functional corrections.
8. **Reduce visual work on the server after correctness.** Cache rigs, move poses/flashes into clients, remove repeated ApplyPersonaLook calls, own transient effects, and make hazard visual updates transition-driven. Measure before/after under capped and worst-case encounters; do not claim a mobile budget PASS without measurements.
9. **Validate complete progression silently.** Run all 20 stages plus hub in the device/layout matrix; include required turtle goals, boss victory, death/rejoin/restart, popup sequencing, and no-audio verification. A silent uncoached tester should understand each action and hazard from text/visuals alone.

### Required test matrix

| Area | Minimum meaningful scenarios |
|---|---|
| Startup | Compile all files; require graph; empty/fresh/existing character; missing optional assets handled explicitly |
| Combat math | Every persona × melee/ranged/thrown representative; lowest/highest speed; thresholds and overkill; dead/ally targets; actual damage/heal result |
| Control timing | Keyboard/gamepad/touch; 30/60/120 FPS; representative latency; held/repeated inputs; UI focus; direction change before skill |
| Movement | Jump hold/cut/coyote/buffer; scaled avatar; grounding near VFX; dodge on ground/air; all speed/slow combinations |
| Collision | Every telegraph boundary in X/Y/Z; dash against barriers; projectile hitch/ordering; ground-only attacks versus jumps |
| Hazards | Active/inactive; overlap; resistance; iframe; edges/corners; failed pad; safe recovery; conveyor/wind integration |
| Enemy lifecycle | Kill/reuse during windup; repeated hits; phase crossings; pool exhaustion; destroyed models; summoned adds at cap |
| Run lifecycle | Death/restart; stage advance; credits/hub; disconnect with active effects; callbacks from old generations rejected |
| User communication | Small necessary popup text only; no blocked attack during incidental dialogue; no stale popup; no audio instances/playback requirement |
| Performance | Server simulation time, replication, mobile frame time, instance count, task count, and map sizes over a complete run/retry |

No statement in this report certifies “no remaining bugs.” Release confidence requires concrete executable evidence for the scenarios above, and the final report should label remaining runtime tests as unverified rather than converting them to PASS.
