# Gameplay, world, content and progression re-audit — 2026-09-05

This pass repaired ten core defects plus the bounded content-honesty and R6/R15 integration issues documented below in the gameplay/content workstream. It re-read the current source after the September 4 repairs, followed actual producers and consumers, and checked production stage coordinates rather than treating a passing rule test as proof of a playable level. The user's reported failed E interactions and crowded interface were the trigger. Startup, client interface, persistence and movement authority have parallel reports; this document covers their gameplay integration and the source changes owned by this workstream.

**Evidence boundary:** the author did not launch Studio, build the place, publish, download assets, or run a browser. Targeted pure Luau suites were run with the already installed Luau 0.737 executable. The root reviewer supplied the real Studio screenshot `docs/reaudit-evidence-2026-09-05/build03-hub.png`, which was visually inspected here; it confirms severe hub glare. The root separately reported a real E press entering Daytona in build 03. Those observations do not validate the later gameplay patches. Full compiler/type/package and engine results belong to the root's final validation record. No audio was introduced. Required story remains small, nonmodal popup text.

`REAUDIT_GAMEPLAY_2026_09_05_SOURCE_HASHES.json` records the source snapshot after the first integration hold (world label cleanup and delayed-attack validation), before the second repair set. The final hashes are recorded separately when the repair set is frozen. Other workers had authorized changes in this checkout; no source rollback was performed. References below describe this workstream's post-fix source unless explicitly labelled **before**.

## Repairs and actionable verification

### G01 — P1: world labels competed with interaction prompts and tutorial text

**Trigger / actual:** join the hub. The bonfire instruction, Steve's name plus a second E instruction, cooler prose, newsstand masthead, headline board, native prompts, HUD and popup all occupied the same small camera view. Most world labels were 240×44, scaled, always on top, and had no distance limit. This is a source-proven overlap risk, consistent with the root's baseline and build 03 images. The duplicate E wording also implied a second input surface even though only the native prompt had interaction behavior.

**Expected:** the character and nearby actionable object remain readable; the native prompt supplies its action and identity, while necessary dialogue uses the small popup queue.

**Fix / owner:** `WorldBuilder.lua:51` now limits remaining spatial labels to 160×28, 14-point text and 40 studs, with occlusion respected. `_BuildHub` at line 706 no longer creates the five duplicate billboard surfaces or the headline board. Hazard instructions were shortened to identifiers such as HOT OIL and DEEP WATER. The Cold One label identifies the pickup. The shared prompt constructor at line 71 and `EnemyService.SpawnTurtle:152` specify E and gamepad LB. EnemyFactory no longer appends another Press E to turtle names. UI input routing remains client-owned; world construction only supplies prompt metadata.

**Verification:** source review found the redundant hub labels removed and E/LB declared in both prompt constructors. Engine regression: fresh join, walk between bonfire and Steve, show only the relevant prompt, press E and LB once, then rescue a turtle with both devices. Repeat at 1280×720, 360-pixel touch width and enlarged text. Do not count this source patch as proof that prompt routing works; root's build 03 E observation validates only its frozen package.

### G02 — P2: hub light and emissive effects obscured the hero and Steve

**Trigger / actual:** the inspected build 03 hub screenshot shows most of the foreground saturated orange/yellow, with the player behind the fire and Steve rendered as a bright silhouette. Source explains the result: a 2.8-brightness, 32-stud orange point light, a flicker range up to 3.5, bloom, high-emission fire particles, a neon spawn pad, and neon Steve accents all overlap.

**Expected:** warm dawn lighting with visible body, facial, prop and ground silhouettes. A nearby fire should not wash out the playable foreground.

**Fix / owner:** hub-specific settings in `WorldBuilder.ApplyLighting:112` reduce bloom to 0.08, size 8 and threshold 1.6, reduce atmospheric haze/glare, and use neutral ambient/tint. Bonfire light at line 784 is 0.35 over 14 studs, flickering only 0.30–0.45. Fire rate falls 36→14 and sparks 10→3, with emission 0.45. The ember bed, hub spawn pad, Steve's beak and crest use non-neon materials. Other stage lighting profiles are unchanged by this targeted repair.

**Verification:** visual defect confirmed from screenshot; repair reviewed in source only. Capture the same camera position in the new build at default and reduced-flash settings. Require clearly distinguishable player limbs, Steve's eye/beak and bonfire logs, including low graphics quality. Compare night/facility scenes separately; this repair does not certify all twenty lighting profiles.

### G03 — P1: delayed positional consumers could bypass movement authority

**Trigger / actual:** an enemy attack resumes after its telegraph coroutine delay. Its target position was read directly from the client-owned character outside the direct-action guard. The newly separated HazardService also returned early whenever MovementAuthority rejected a position, which would let repeated invalid positions suppress every hazard evaluation even when the player was corrected back into danger.

**Expected:** every consequential spatial decision uses the accepted position. A rejected move earns no damage immunity.

**Fix / owner:** `EnemyService._TelegraphAttack:692` calls MovementAuthority.Validate immediately before reading the target root for hit geometry. `HazardService.Tick:131` validates/corrects and continues evaluation rather than returning on false. Neither layer invents its own speed or displacement permission. Authority remains in the dedicated movement module, with server-issued dash/pad/impulse grants.

**Verification:** source trace confirms validation precedes both consumers and no false-result escape remains in HazardService. Engine adversarial regression: place a player within an active hazard and an enemy's committed attack region; repeatedly submit out-of-envelope positions. Observe corrections, normal damage at the corrected location, no hazard-free frames caused by the rejection, and no reward for crossing a locked gate. Separately verify legitimate high-speed builds, dodge, pads, wind, recovery and a normal jump remain accepted. The movement report owns the pure envelope tests.

### G04 — P2: overlapping hazard damage depended on table iteration order

**Trigger / actual:** overlap two active damaging parts. Before repair, `HazardService` iterated a hash table, applied the first qualifying damage, and immediately consumed the shared LastHazardAt cooldown. A3-damage puddle could suppress a 7-damage ring, and a non-impulse hazard could suppress a pipe launch. Registration/iteration order was an accidental game rule.

**Expected:** the same simultaneous hazards produce the same outcome, independent of insertion or enumeration order. Oil mitigation must be applied before choosing the strongest hit.

**Fix / owner:** new pure `HazardRules.lua:10` merges overlaps. The server adapter first collects active geometry, then applies one maximum post-mitigation damage tick per 0.8-second cooldown; environmental velocities add and are clamped once; the strongest eligible upward impulse is applied once. Multiple jump pads similarly select one strongest boost. Oil slow, general environmental slow and water exposure are independent flags. Source geometry and cooldown scheduling remain in HazardService, not the data catalog.

**Verification:** `tests/hazards.test.luau` passed all 5,040 permutations of seven overlapping definitions, checking damage, impulse, both motion axes, both slow flags and water. A separate case verifies resistant slick damage 3 cannot suppress ordinary sample damage 5. Engine regression: overlap a sample, pipe, ring and pad; reverse creation order; compare HP loss, impulse revisions and launch height. Also verify i-frames suppress hazard damage/impulse while a jump pad remains usable, and death during the tick stops mutation of the old character.

### G05 — P2: an oil-specific build bonus also resisted sand, water, tide and paperwork

**Trigger / actual:** equip three GREASY inscriptions and enter a non-oil slow. Every `def.slow` wrote OilSlowUntil, and CharacterStatePublisher applied oil resistance to that attribute. CondoKaren also wrote the oil channel. The in-fiction damage type had leaked into a generic status channel, so a specialized build bonus changed unrelated mechanics.

**Expected:** GREASY milder slick slow and half oil damage apply to the advertised oil category. Environmental slow remains effective.

**Fix / owner:** `HazardDefinitions.lua` types slow as `oil` or `environment`. `HazardRules.SlowMultiplier:21` selects the strongest simultaneous multiplier without compounding. `CharacterStatePublisher:72` consumes a separate EnvironmentalSlowUntil. HOA paperwork writes that channel in `EnemyService:715`. Hazard duration uses the longest existing expiry instead of shortening another active effect. Both channels clear on hub/stage transitions in StageFlowService.

**Verification:** pure tests passed oil resistance 0.88, environmental slow 0.70 despite resistance, mixed-effect minimum 0.70 and clean expiry 1.0. Engine regression: wear GREASY, step into each of oil, sand, canal and red tide, then receive HOA slow; measure accepted MoveSpeed and expiry. Repeat across a stage transition and death to ensure no stale slow survives. Test non-GREASY and simultaneous hangover/oil/environment combinations.

### G06 — P2: several enemy kits faced sideways or failed to turn at attack range

**Trigger / actual:** a lizard, humanoid, boss, pelican, drone or slime moves along X. Most AI branches previously used yaw 0/π, even though those kits are authored toward−Z. HermitCrab's tank branch also differed from the crab scuttle branch. All families could update logical Facing while standing within attack range without rotating their visual model. Gators and snakes are authored+X and were correctly oriented while moving; they must not receive the same correction as the−Z kits.

**Expected:** a creature's visual front, movement and committed attack agree. Imported art retains its validated+X convention.

**Fix / owner:** `EnemyMovementRules:5` declares the fourteen procedural shape axes and computes the required yaw. EnemyFactory records VisualForwardAxis/VisualFacing for procedural and imported models at lines 1173 and 1226. EnemyService uses one pivot adapter for movement, burrow reposition, stationary turning and windup commitment. `CombatService.InHitVolume:197` now uses world-space extents of rotated non-square roots rather than treating local dimensions as world dimensions.

**Verification:** pure enemy-movement suite passed containment plus all fourteen shapes in both directions, preserving gator/snake and imported+X. Engine matrix: observe each family moving left/right, cross behind it while in range, attack while it is stationary, knock it back, and inspect its collider overlay. Include imported test art with a+X marker. World-space extents are source-reviewed; actual CFrame/render/collision alignment still needs engine verification.

### G07 — P1: Snake Charmer's lingering skill could miss small grounded enemies

**Trigger / actual:** use Coil Call next to a crab or snake at ground level. Before repair, SkillService passed the player root position, and CombatService placed the volume another stud above it. At ordinary rootY=3 this produced centerY=4. A BeachCrab root at Y=1.3 with half-height 0.44 is 2.7 studs away, exceeding the old hit height 2+0.44. A BurrowSnake root at Y=1 with half-height 0.5 also misses. The rendered three-stud volume and queried four-stud height additionally disagreed.

**Expected:** the ground-level coil bites small ground enemies inside its visible volume, including the snake family that unlocks the persona. Jumping should raise both the real volume and its visual together.

**Fix / owner:** `CombatGeometry.GroundedCenterY:9` derives the center from character feet plus half the volume height. `SkillService:76` supplies that center and height. `CombatService.SpawnLingeringHitbox:400` places exactly the supplied center and queries the rendered Part's half-width/half-height. The shared geometry layer owns math; the skill owns semantic placement; the runtime adapter owns the Part and lifetime.

**Verification:** pure geometry suite passed five grounded body-height cases, jumping height, normal ranged muzzle and lane separation. Engine regression: coil beside BeachCrab, BurrowSnake, Cottonmouth, EmberSkink and a humanoid, each on both sides; test just outside the visible volume, above it on a ledge, across a wall and while the caster jumps. Confirm six intended ticks over the two-second default duration at normal scheduling, no hits after stage/death cancellation, and no friendly turtle damage. Tick count under engine scheduling must be measured rather than inferred from a nominal interval.

### G08 — P2: healing from delayed hits could leave displayed HP stale

**Trigger / actual:** with HEROIC lifesteal and less than full HP, fire a projectile or create a coil, then stop issuing actions. The command published its snapshot before the delayed impact. `AttackService.HitEnemy` changed `s.hp` after impact but did not publish it. The main simulation loop does not periodically publish HP; a nonlethal hit therefore leaves the HUD stale until another state-changing event.

**Expected:** visible HP tracks accepted healing as soon as the impact is resolved, and overkill never grants extra healing.

**Fix / owner:** `AttackService.HitEnemy:69` derives healed HP through `CombatGeometry.HealFromDamage:13` and calls PushState only when HP actually changes. It still uses EnemyService's damageApplied result. No client-supplied health or prediction is trusted.

**Verification:** pure tests cover applied-damage healing (80→80.48 from 8 damage), max-health clamping and unchanged full HP. Engine regression: fire one nonlethal ranged shot with a HEROIC build while damaged, release all input and compare HP snapshot/HUD at impact. Repeat with a coil, overkill, full HP, a stage clear during flight and a player death before impact. Publication frequency should scale with accepted healing, not every render frame.

### G09 — P2: the first stage could finish without reclaiming the stolen drink

**Trigger / actual:** jump over the can at 42% of Daytona, clear enemies and enter the exit. The pickup required distance<6, but CanComplete checked no Cold One flag. The stage blurb/story explicitly require reclaiming it, and credits assert it is yours. This was a real missing progression connection, not merely optional flavor.

**Expected:** the required pickup is either completed or the exit gives a clear remaining objective. Later stages without the pickup are unaffected.

**Fix / owner:** `ProgressionRules.CanComplete:19` requires coldOneTaken only when stage.coldOnePickup is true. `StageFlowService.FinishStage:287` delivers one small exit reminder, deduplicated per run. The authoritative snapshot now includes coldOneRequired/coldOneTaken (RunContext.lua:135), and the client compact objective consumes them (HUD.lua:184). Catalog data owns which stage requires the objective; the progression rule owns permission; UI only explains it.

**Verification:** pure progression suite passed missing-can rejection, collected-can acceptance, and remaining-enemy rejection. Engine regression: deliberately jump over the can, defeat the miniboss, reach the exit, receive one reminder, backtrack, collect it and leave. Repeated exit ticks must not fill the popup queue. Verify death/restart resets the pickup and reminder, and later stages/finale are not blocked by their unused per-stage coldOneTaken flag.

### G10 — P2: set-piece collision silently filled Barge Crossing's real gap

**Trigger / actual:** traverse production BargeCrossing. LayoutPlan's actual stage/wave reservations retain a gap[72,78] and remove the other candidate gap to protect a wave landing. WorldBuilder then created its first solid deck centered 68, width 26: [55,81], completely bridging the only real gap. Prior tests proved the ground plan but never tested the set-piece colliders laid on top. The level promised gaps while offering an unbroken floor there.

**Expected:** decorative and set-piece construction honor the authoritative traversable layout, including reserved holes and landings.

**Fix / owner:** `LayoutPlan.SupportedSlices:41` clips an arbitrary support object against non-gap spans. WorldBuilder's barge deck at line 574 uses those slices, producing first-deck segments[55,72] and[78,81]. Layout owns support truth; the renderer may no longer overwrite it with a second floor policy.

**Verification:** production-stage test uses BargeCrossing's real length/index/wave progress values, asserts the real gap, asserts the split deck and verifies every generated deck slice is supported. Engine regression: visualize all colliders, walk into the gap without jumping, then cross normally and via a pad/ledge; ensure safe recovery is reachable. Test both approach directions and the fast build. Other set-pieces must be included in a future collider-union acceptance test, not just the ground manifest.

## Bounded cleanup completed after the first repair set

### G13 — P3: the solo aggro effect had no observable behavior

**Before:** LiveBait advertised interested enemies, published AggroPull and weighted target choice by 0.72. The supported experience admits one player, so there is no alternate eligible player to choose. Its flat damage bonus was real; the special was ineffective.

**Fix:** `Items.lua:29` now describes the real damage item without a targeting promise. Its numeric stats are unchanged. The unused special, character attribute publisher and enemy targeting weight are removed. A caller search across src/tests/scripts/qa found no remaining AggroPull or aggro special reference. No artificial aggro system or multiplayer mode was introduced to justify unused code.

**Regression:** obtain LiveBait and verify its damage/build stats remain unchanged. The item description should not promise altered enemy attention. This is source cleanup; no new balance rule was added.

### G14 — P3: retired names and dead implementation paths overstated current features

**Before:** collapsingPier created static planks; turtleEscort and its dormant auto-rescue movement branch coexisted with immediate interaction rescue; Story.CREDITS contained an unused long ending; several constants and one-dimensional attack helpers had no callers. A conditional after-first-death slot alias obscured the actual three-slot starting rule even though both branches returned 3.

**Fix:** both the stage and builder now call the static structure `pierWalkway`. The semantic verb is consistently `turtleRescue`; the unreachable escort movement, goal/enable attributes and escort constants are removed. The unused Story.CREDITS is deleted, leaving the real dynamic ending in StageFlowService. Unused attack-buffer, old currency-refund, generic-stage-length, old HOA damage, old wind and cancel-flash constants were removed after caller inventory. Unused Balance.WaveSpawnCap, CombatService.InLaneMelee/InLaneRange and the empty rescue billboard branch are removed. Live hitstop and rescue debounce behavior remain. The root coordinated RunContext's starting slot assignment and removed the after-first-death alias.

**Regression:** source searches confirm no obsolete caller remains; full compiler/type/contracts belong to the root's final frozen validation. Check the first stage still builds its pier, rescues require one accepted Interact, fresh and returning players both start with three slots, and credits still show actual run/lifetime counters. No active rewards, stats or traversal rules were tuned by this deletion.

### G15 partial closure — the apparent weak point is now ordinary armor

The decorative `WeakPoint` in `EnemyFactory.lua:827` had no special damage rule. It is now named ArmorPlate, uses a muted body/accent blend and Metal instead of bright Neon. The silhouette remains. This removes a false critical-target affordance without inventing damage bonuses. The broader visual/hitbox alignment acceptance described below remains open; it requires rendered collider contact sheets.

### G17 — P1 integration: combat and tutorial must share rig-aware feet

The root's engine work exposed the R6/R15 standing-height difference and added CharacterGeometry. The first gameplay geometry pass still used HipHeight plus half the root, which omits R6 leg length. For a default R6 rootY3/height 2/HipHeight 0, that put the inferred feet atY2 rather than groundY0; a seemingly grounded projectile/coil could still miss low enemies and ground telegraphs could miss the player's actual feet.

AttackService projectile placement, SkillService coil placement, EnemyService delayed hit geometry and TutorialService floor observation now call CharacterGeometry.FeetDistance. CombatGeometry receives the already-derived standing distance instead of interpreting rig-specific dimensions. This puts rig structure in one shared geometry owner and leaves skills responsible only for offsets from the feet. HazardService, MovementAuthority and the mover consume the same helper under the root's integration.

**Verification:** the pure combat suite passed both `StandingHeight(0,2,2)` for R6 and `StandingHeight(2,2,nil)` for R15, proving identical 1.2-stud muzzle and 1.5-stud coil centers for feet on ground. The five targeted suites passed again after cleanup. Engine regression must include real R6 and R15 avatars, scale variations, jump recognition, low enemy hits, telegraph/hazard damage, ledge standing and respawn. These checks were not executed by this workstream.

## Remaining concrete debt and acceptance work

These are open work, not statements that the repaired build failed engine tests. Source-only confidence is distinguished from an observed effect.

| ID / priority | Evidence and implication | Action / owner | Meaningful acceptance |
|---|---|---|---|
| G11 / P2 | `CombatService.SweepEnemy:237` sweeps horizontal motion and retains rootY; most `EnemyService` branches use a fixed BaseY/rootY. WorldBuilder creates raised pier planks, docks, pipe platforms and deck steps. There is no general step-up, floor-following or gap-navigation policy. Source confirms the missing behavior; which specific spawn becomes stuck requires engine reproduction. | World/navigation owner: define grounded, hopping, flying and burrowing traversal classes. Add bounded step-up/down and explicit gap policy, preserving server collision authority. Avoid teleporting every blocked enemy through obstacles as a universal fallback. | Crab approaching a pier step from both directions; a gator at dock edges; humanoid on a pipe platform; flyer over a real gap; queued enemy behind a closed gate; spawn initially intersecting a prop. Measure stuck duration and complete the stage without test damage. |
| G12 / P2 | `EnemyService.ApplyDamage:224` refreshes 0.18s flinch and invalidates attacks on every ordinary hit. Several fast weapon/persona recoveries are shorter; only Spillfather phase transitions gain temporary hyperarmor. This establishes a potential lockout mechanism, not proof that the complete game is too easy. | Combat/balance owner: measure continuous light-attack stun uptime for fast builds before adding an elite stagger budget or diminishing returns. Keep small enemies responsive to attacks; expose any new armor visually. | Repeated attacks against each miniboss with Pool Noodle/Golf Cart Bandit; record whether any attack can resolve, actual accepted attack rate and player exposure. Compare starter and slow heavy builds. |
| G15 / P2 | Grounded collision is root/hitbox based; procedural silhouettes deliberately extend beyond root.Size, and imported roots use def.size. After orientation repair the server queries correct rotated extents, but visual limbs and armor still lack a certified hitbox/feedback relationship. | Art/combat owner: produce an engine contact sheet with collider overlays for all families, including the repaired muted boss ArmorPlate. Clearly distinguish cosmetic accents from real critical-hit targets. | Attack limb, torso, armor and empty space around each silhouette; record the intended accepted/rejected hits and confirm the plate no longer suggests a critical target. No sprite or uploaded-animation readiness claims based only on registry slots. |
| G16 / P2 | `HazardService.safeSupportAt:71` scans registered hazards and performs support/clearance queries; EnemyService still presents procedural rigs from the server. Caps bound hostile count, but there is no measured CPU/network budget for the full set-piece/effect load. | Runtime/performance owner: profile one worst-case stage and a repeated death/restart loop before optimizing. Reuse support query parameters/candidate neighborhoods if the measured cost matters; move purely visual enemy animation to client presentation only with a stable semantic animation state contract. | Record client/server frame time, instance counts, connections, replicated movement/animation traffic and memory at start, worst encounter and after ten resets. Check that all counts return to a stable baseline. |

## Stage-by-stage coverage

The twenty stage definitions and hub were read. All wave IDs, miniboss/boss demand, turtle counts, objective predicates, midgate selection, progression drops, lighting/set-piece selection and real gap planning were followed to their consumers. This table reports design/source coverage, not twenty completed playthroughs. Every row still needs an ordinary-input traversal in the root's engine acceptance matrix.

| Stage | Source mechanics and narrative connection | Specific regression focus |
|---|---|---|
| Hub | Bonfire start; Steve dialogue/shop; saved loadout; tutorial movement/jump; neutral dawn fire scene | E/LB action, prompt exclusivity, glare repair, no overlapping prose, no audio |
| 1 DaytonaHangover | Three waves; CrabKing miniboss; hangover; required Cold One; static pier | Jump past can then backtrack; crab step navigation; first unlock, first reward, no story bypass |
| 2 BoardwalkChaos | Tourists/flea/selfie/cart; timed fryer oil; early 2-hostile cap | Charger facing; both sides of flash strip; raised fryer ledges; queued waves drain |
| 3 GasStationLegends | Slime/selfie/HOA; SlushieKing; first room lock; GolfCart unlock | Slime orientation; typed paperwork slow; first midgate; duplicate persona award idempotence |
| 4 StripMallShowdown | Karen/cart/selfie/tourists; HOAHydra summoner | Summon capacity, no unbounded reinforcement queue, boss facing, remaining adds block exit |
| 5 DriveThruDisaster | Cart/slime/crabs; DriveThruGator; confirmed collar clue | Preserve gator+X; kill-triggered story only once; GatorHauler and weapon rewards |
| 6 CanalRun | Jet ski, burrow/cottonmouth, cloud; real small gap; pads/water; capacity 4 | Pad launch accepted; non-oil water slow; burrow geometry; first SnakeCharmer unlock |
| 7 SwampShift | Oil gator/fire lizard/skink; slick/fire mix; mutant collar reveal | Low targets hit by coil; lizard facing; mixed hazards and oil resistance |
| 8 CypressCathedral | Summoners/cottonmouth/burrow/adds; canopy/slick | Summon cap, snake+X, corpse/queue cleanup, two casts then stage reset |
| 9 SludgeBayou | Puddle layers/oil gators/skinks; multiple slicks | Deterministic overlap; dynamic puddle expiry and registration cleanup |
| 10 ConspiracyShack | Pelican/lab coat/drone; corkboard links collars→nests | Flyer/humanoid facing, prompt-free static evidence and queued explanatory text |
| 11 TurtleBeach | Corporate crew/red tide/fire/oil; five required rescues; capacity 5 | Every turtle can be approached/rescued, protected landings, rescue-first/kill-first order |
| 12 NestGuard | Drones/red tide/grunts/puddles; four rescues | New stage resets stage count, preserves run/lifetime count; no phantom fifth nest requirement |
| 13 GulfGulpGate | Grunts/welder/barrel/drone/lab coat; conveyors; hostile cap 4 | Conveyor direction and motion grant; branded gate is scenery, midgate owns lock |
| 14 LabWing | Mutants/lizards/gators/lab coat; moving samples, conveyors, pipe bursts; lab memo | Highest mitigated overlap damage, impulse selection, moving-hazard registration, story delivery |
| 15 PipeGauntlet | Barrels/welder/puddle/grunts; RigOverlord; pipe platforms | Ground navigation risk, projectile occlusion, boss fire telegraph, accepted dash sweep |
| 16 LoadingDock | Offshore/hermit crabs, grunts/barrels; dock/conveyors; capacity 6 | Hermit tank-facing correction; raised dock navigation; sixth slot exposure |
| 17 BargeCrossing | Storm pelican/jet ski/offshore/drone; real deck gap and wind | G10 split deck regression, safe recovery, flying vs grounded navigation policy |
| 18 OilPlatformApproach | Welder/gator/drone/lizard/add/barrel; walkway/slick/fire/conveyors | Dense mixed effects; ranged line-of-sight from raised walkway; final clue sequence |
| 19 HelipadHysteria | Grunts/lab coat/storm pelican/puddle/welder/adds; wind/slick | Opposing wind additive contribution, no cumulative Y drift, fast-build dodge |
| 20 GulfGulpRig | Five waves; Spillfather with threshold phases/adds/ring; three required rescues | Boss-first and turtles-first both require other objective; post-mitigation ring damage; remaining adds; once-only finale rewards and credits return |

## Catalog and power coverage

**Weapons:** all 28 definitions and the 27 nonstarter stage unlock entries were compared. Eighteen melee IDs (BareHands, FlipFlopSlap, GolfClub, GatorWrestleGloves, SpillSkimmer, PoolNoodle, CoolerLid, BeachUmbrella, KayakPaddle, BugZapper, ShoppingCart, PelicanBeakReplica, TikiTorch, Skateboard, FishSmack, NewspaperRoll, HOAClipboard, BoogieBoard), five thrown IDs (LawnDart, SnakeLasso, TrafficCone, OilBarrelLid, FinaleRocket), and five ranged IDs (RomanCandle, FireExtinguisher, WaterBalloonSling, NetGun, SludgeHose) use real attack branches. FoamFire and netRoot are semantic fields rather than presentation-name switches. Flat muzzle, swept travel, obstacle cutoff, finite pierce and generation cancellation remain connected. FinaleRocket is intentionally awarded at final clear for a later adventure; its availability during the finished finale is not claimed.

**Personas:** all eight skill paths were followed: BeachBurnout wave; CrabKing dash; GatorHauler AOE; SnakeCharmer lingering coil; GolfCartBandit armored dash; FireworksEnthusiast AOE; LizardBreath beam with the OilGator matchup; TurtlePaladin heal/shield. Eight three-strike movesets supply real damage/range/knock/recovery/cancel values. Persona rarity changes damage and skill cooldown through Balance. Skill/swap/dodge cooldowns are server-owned; cancelling attacks does not invent a second client permission source.

**Enemies and art:** all 34 definitions (33 hostiles and one rescue ally) connect to fourteen procedural shape families. Axis mapping now covers crab, gator, lizard, snake, slime, humanoid, boss, turtle, hopper, cart, drone, pelican, barrel and cloud. Imported models retain the+X contract. No raster sprite pack or new uploaded animation was generated. The four populated persona clip bags each contain nine empty slots; the remaining personas use procedural fallback. Existing `IMPLEMENTATION_CLIENT.md` contains the exhaustive per-ID source visual matrix. An empty registry is an implemented fallback choice, not evidence of authored-asset delivery or visual approval.

**Items:** all 28 IDs and six inscription sets were inspected. Flat HP/damage/speed/luck/dodge modifiers derive in BuildRules; pickup healing is granted only after inventory acceptance; three unique matching inscriptions unlock a set. `stageHeal` is consumed on clear; `paperCut`, `radio` and `ember` in accepted hits; `sunburnFind` in kill rewards; `absorb` in incoming damage; `badge`/`antiCorp` in build derivation; HEROIC in actual-damage healing; GREASY in the corrected typed hazard policy. Duplicate ownership and slot overflow are rejected through ItemGrantRules. Enemy drops at full capacity are declined instead of opening a replacement draft; this is an existing explicit rule, but the quiet decline deserves user testing. The obsolete solo `aggro` effect was removed under G13; its flat damage remains unchanged.

**Scaling:** source still uses HP×(1+0.09×stage), damage×(1+0.075×stage), softer Act 1/2 miniboss multipliers, hostile caps 2→3→4, capacity 3→4→5→6 on stages 1/6/11/16, and rarity damage 1/1.15/1.30/1.50 with cooldown 1/.92/.86/.80. The phase thresholds are 66% and 33%; a large hit can jump directly to phase 3. These relationships are connected; they are not a balance certification.

Useful test builds, derived from the current rules rather than a stale spreadsheet:

| Build / scenario | Source-derived value | What to measure |
|---|---|---|
| Common BeachBurnout, BareHands, no items | Three hits total 40.56 damage over 0.60s of recovery, an idealized 67.6 DPS ceiling before input cadence, approach, knockback and misses | Real accepted attack rate and stage 1 time-to-kill; historical 36–48 DPS notes are not the live formula |
| Damage: HeadlinePressPass, HOACitation, LabBadge, LawnDartCharm, BonfireEmber, GatorSkinWallet | Damage multiplier 2.93, HP135; Legendary adds×1.5; ember/crit remain situational | Whether elites can retaliate, meaningful defense tradeoff, actual boss TTK |
| Defense: RedTideFilter, SpillAbsorbent, OilProofBoots, CrackedVisor, SeashellShield, TurtleSticker | HP182; three absorb specials multiply incoming damage by 0.75³ before rounding; HEROIC healing enabled | Survival under multiple attacks; rounding behavior; shield consumption order; prolonged boss damage |
| Mobility with three HUMID and strongest other cooldown items | A feasible 0.34 dodge reduction gives 0.4752s cooldown versus 0.38s protection; server motion grants remain separate | Exposed interval, swap/Cart skill chains, fast traversal vs hazards and gaps |
| No-upgrade/poor-draft run | No guaranteed per-run rarity upgrade; stage 20 Spillfather HP952 before phase mechanics | Complete an ordinary-input run with weak luck as well as a favorable build; do not retune solely from ideal DPS |

**Options and story:** the current shared options expose shake, colorblind telegraphs, reduced motion, reduced flashes, large text and three text speeds; audio is not an option. Server settings reconciliation, responsive layout, popup queue/focus and device input are audited in the client report. The five-act arc, required collar clue, lab evidence, turtle rescue demand, once-only reward ledger, dynamic run/lifetime counts and later-adventure finale reward were followed. Stage summaries/credits and gameplay dialogue must be reviewed as separate presentation surfaces; no server progression permission depends on dismissing ordinary story text.

## Layer responsibilities checked

| Layer | Owns | Result / remaining boundary work |
|---|---|---|
| Shared catalogs | Declarative stages, weapons, personas, items, hazard definitions, semantic effect IDs and presentation defaults | Correct direction. They do not authorize shop commands or grant saves. G05 gives slow an explicit category. A branded badge is fiction, not auth. |
| Pure rules | Geometry, build derivation, completion conditions, overlap merge, support slices and facing math | Correct ownership after G04/G05/G06/G09/G10. Rules take inputs and return values; no remotes, Players, world mutation or provider calls. |
| MovementAuthority | Accepted movement, finite action/impulse grants and corrections | Gameplay consumes it immediately before delayed spatial decisions. Client presentation is not proof of legality. G03 closes the missing consumer paths. |
| Combat services | Cooldowns, accepted hits, shields, actual damage, skill semantics, lifecycle cancellation | Runtime truth stays server-side. G07 fixes skill placement and G08 publishes accepted healing. G11/G12 remain traversal/balance work. |
| EnemyFactory / WorldBuilder | Build visual/physical objects and metadata from definitions | Factories do not grant unlocks. WorldBuilder previously overrode layout truth by filling a gap; G10 fixes that leak. Server enemy animation remains a deliberate implementation debt, not entitlement logic. |
| StageFlow / ProgressionRules | Stage lifecycle, required objectives, reward ledger, rescues, finale commitment | G09 connects the Cold One requirement. Completion never derives from UI visibility, a headline or client acknowledgement. |
| RunContext / CharacterStatePublisher | Server session projection and accepted character attributes | HP publication repaired; character status now consumes typed slow results. Profile/provider ownership remains elsewhere. |
| Client input/UI/animation/camera/VFX | Express intent, render accepted state, predict motion for responsiveness, present small silent text | No damage, unlock, purchase, rescue count or completion authority belongs here. Root/client report owns the E crash repair and clutter reductions. |
| Persistence, profile provider, release tools | Durable records/provider failures, session lease, private QA tooling and immutable package evidence | Reviewed by the parallel security/architecture workstreams. No new provider, auth, paid entitlement, AI memory/control policy or external service was added in this scope. |

There is no claim that unrelated AI/provider/auth systems exist merely because the user's audit checklist names them. In the reviewed game source, the corresponding real boundaries are server-earned unlocks, profile writes, settings, movement trust and release instrumentation.

## Completion plan and release gates

1. **Freeze and validate this repair set.** Parent runs full Luau compile, Roblox-aware typecheck, source contracts, all meaningful pure suites and a sequential package build. Preserve the exact source hashes and distinguish the build 03 engine observations from this later package. Fix actual failures before continuing.
2. **Repeat the user's failed flow with real input.** Fresh join→E bonfire→Daytona; return→E Steve→shop→close→start again. Repeat LB and touch. Confirm the hero remains visible and the prompt does not compete with a wall of labels. Exercise the popup at slow/instant text, dismissal, stage change and death, in silence.
3. **Run the new gameplay regression matrix.** Missing Cold One, low enemy coil hits, delayed lifesteal HUD, all facing axes, mixed hazard permutations, corrected-position damage and Barge gap. Use both rejection cases and successful cases. A scripted kill/teleport smoke checks service composition but does not replace this traversal matrix.
4. **Traverse every stage with ordinary controls.** Include starter, heavy, ranged, thrown, mobility, defensive and weak-draft builds. Record enemy stuck positions, unreachable turtle prompts, failed landings, missed attacks, time-to-clear and damage taken. Repair G11 only after a bounded traversal policy is chosen and reproduced in-engine.
5. **Measure power and readability.** Log accepted attack rate, real TTK, uninterrupted stagger duration, dodge exposure and UI/danger-area occupancy. Address G12 using observed data. Do not scale enemy HP blindly to compensate for an animation, input or hitbox defect.
6. **Finish content honesty cleanup.** Solo aggro, static-pier naming, retired escort/credit code, unused constants and the false weak-point affordance are repaired. Complete item decline feedback and every art readiness claim after reviewing the actual user experience. Retain concise game-facing descriptions; implementation terms stay in technical reports.
7. **Visual and device acceptance.** Produce family contact sheets with colliders, all weapon presentations, skill effects, stage lighting and options. Test partial/missing authored assets and respawn fallback. Cover smallest supported touch viewport, gamepad focus and default/enlarged text. Verify zero audio throughout.
8. **Profile and lifecycle acceptance.** Measure worst-case stage performance and ten death/restart cycles, then optimize measured costs. Verify delayed enemy attacks, projectiles, coils, telegraphs, puddles, timers, connections and motion contributions cannot survive into a new stage/run. Keep provider failure and save/rejoin acceptance in the security owner's suite.

The source repairs are complete for G01–G10, G13, G14 and G17 in this workstream, and G15's misleading weak-point affordance is removed. Targeted pure tests passed. Engine, device, full-campaign, visual and performance gates remain explicit until the root's evidence closes them; neither this report nor a successful compiler run is a claim that every remaining defect has been eliminated.
