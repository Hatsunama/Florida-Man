# Client implementation and staged source audit

Date: 2026-09-04. Scope: W1, W4, W8 and the client side of W5 in PLAN_2026_09_04_IMPROVEMENTS.md. Source owned by this work: src/client/**, shared Settings.lua and ArtAssets.lua. Backend/session/economy/world fixes are recorded by their owners.

This is implementation evidence and a remaining acceptance checklist. No Studio session, screenshot, phone/controller session, imported-asset permission test, or measured FPS was run by this worker. Root's sequential compiler/type/domain checks are separate evidence under artifacts/validation-*; later engine evidence must be recorded separately.

## Stage 1 — silence, small conversations and truthful readiness

Implemented:

- Removed AudioDirector and every client PlaySound listener/call. Removed the obsolete client TutorialController; accepted tutorial progress has one server owner.
- Settings no longer contains any audio toggle. Five visual boolean settings are ShakeEnabled, ColorblindTelegraphs, ReduceMotion, ReduceFlashes and LargeText; TextSpeed is slow/normal/instant. Defaults cannot restore audio.
- SilenceController suppresses existing/new Sound and AudioPlayer instances, including Volume/playing changes and respawns, with cleanup on destruction. Root also owns the default RbxCharacterSounds override and removal of shared/server audio production.
- Tagline accepts a structured message with id, generation, scope, priority, essential, speaker and text. It wraps into short bubbles without taking movement/combat focus. First advance reveals; the next advances exactly once. Keyboard T, controller D-pad up and a 44-pixel button share this operation.
- Text reveals with MaxVisibleGraphemes; chunking uses utf8.graphemes, including long words. Required messages wait for explicit advance. Incidental messages have a reading delay. Narrative has run-scoped deduplication and survives fast active-stage transitions; death/hub/new-run boundaries clear prior-run delivery. Accepted lines are also retained in bounded field notes.
- Newspaper summary and the entire ending narrative/counters use that queue. Their compact bottom cards contain progression controls, not full-screen necessary conversation. Credits have no auto scroll or timed return.
- Loading waits for a received authoritative snapshot outside Loading and an actual character root. All event listeners precede ClientReady. A low-frequency handshake retry covers initial snapshot absence; the loading text does not pretend a fixed timer means readiness.
- State acceptance compares generation before stateVersion, so a new RunState whose version starts over is accepted.

Source audit performed after this stage:

- Found and removed the stale init requires of AudioDirector and TutorialController.
- Removed UI compatibility functions that had become empty stubs.
- Found early credits dismissal hiding the GUI without transitioning the server; changed it to DismissCredits and wait for accepted result/stage change.
- Found required queued stage facts being discarded on fast transitions; added explicit run scope, run dedupe and reset boundaries.
- Found potential small-screen overlap and removed automatic full credits panels. Dialogue is clamped to 420 pixels, or 300 in short landscape; the ending return card is clamped to 420 by 108.
- Source search after wiring: zero PlaySound, AudioDirector, MuteMaster/MuteMusic/MuteSFX or new Sound production matches in client/Settings. Sound names remaining in SilenceController are suppression code.

Still requires engine acceptance: assert no default character/UI/combat/ambient/ending sound playback on fresh join and repeated respawn; verify AudioPlayer property changes; stress required message order during rapid reward/stage changes and returning to hub; check grapheme rendering for emoji/combining characters/CJK on all viewport sizes.

## Stage 2 — common input, movement and camera

Implemented:

- InputController.Intent is the action boundary for keyboard, controller, touch and weapon-menu buttons. Mobile controls send no gameplay remotes directly. All devices expose move, variable jump, attack, skill, dodge, persona swap, weapon selection and contextual interaction.
- Client availability consumes server phase Hub/Active and allowedActions.combat/interact. Reward/death/loading/ending and modal inventory/shop panels reject gameplay intent. Small story bubbles never mark themselves modal. GUI gamepad selection keeps A activation and stick navigation.
- Direction is sent with all four combat commands. A short attack buffer and local animation prediction are reconciled with authoritative serverNow/deadlines. Same-persona updates no longer destroy an active animation.
- Context prompts are registered from descendant add/remove; a small proximity pass chooses the nearest valid prompt. It uses ProximityPrompt.InputHoldBegin/End for keyboard E, LB and touch, preserving the same server-validated prompt path. It resolves nested Steve prompts.
- Weapon cycling remains available; Notes lists every owned weapon for deliberate selection. Hub weapon selection is legal, so FinaleRocket and other permanent unlocks can be equipped before the next run.
- Movement is centralized in PreSimulation. Walk speed follows published values without the old 22-stud cap. Ground rays respect collision, exclude the character and require a supporting normal. Coyote time/jump buffering and one-time jump release support variable height.
- Continuous ExternalVelocityX/Y are consumed as velocity contributions, with previous Y contribution removed before applying the next. ImpulseRevision/ImpulseY is one-shot. MotionResetRevision clears cached velocity, jump buffers, impulse reference and external contribution on authoritative recovery/dash/teleport.
- Dodge uses the shared DODGE_DURATION and DODGE_DISTANCE. Its velocity integrates a partial final simulation step, then resets internal velocity to base movement so there is no acceleration-shortened burst or unintended long deceleration tail. A collidable sweep stops fast motion at gates/walls. Rejected RequestDodge cancels the predicted burst; cooldown state remains authoritative.
- Hitstop only freezes animation. It never zeros root velocity or changes damage/timing.
- Camera has a translation-invariant exponential follow and relative deadzone, bounded lag, stage bounds, and bounded focus/arena bias. Character/generation/large teleport/motion-reset changes reset stale camera state. ReduceMotion disables focus/shake.

Source audit performed after this stage:

- Fixed phase-case mismatch and consumption of per-verb keys when the actual snapshot uses combat/interact.
- Fixed keyboard slot 1 cycling instead of selecting slot 1.
- Fixed missing hub selection for unlocked weapons.
- Fixed the first movement implementation treating ExternalVelocityY as acceleration; coordinated velocity semantics with HazardService.
- Fixed acceleration reducing the nominal dodge distance, frame-boundary distance error, and velocity tail after the burst.
- Fixed controller A being consumed as jump while a GUI button was selected.
- Removed repeated full-world prompt scans and stale character equipment connections.
- Requested reviewed StarterPlayer Scriptable computer/touch movement configuration from root, so default Roblox touch controls do not compete with the custom controls.

Arithmetic verification (source formula reproduction in PowerShell, not an engine physics test):

| Check | 30 Hz | 60 Hz | 120 Hz |
|---|---:|---:|---:|
| Integrated 100 studs/s burst over 0.18 seconds | 18.000000000000004 | 18 | 18.000000000000007 |
| Follow scalar translation error after adding 10,000 studs | 0 | 0 | 1.82e-12 |
| Follow target after 3 s at 18 studs/s, then 2 s stopped (start 400; target offset 5) | 458.999999965 | 458.999999967 | 458.999999968 |

These checks establish the algebraic change. They do not establish Roblox collision response, actual device latency, authoritative rejection correction distance, or visual camera framing.

Still requires engine acceptance: all verbs on actual keyboard/controller/touch; simultaneous held touches and device changes; UI focus; 30/60/120 Hz plus long frame; release near apex and platform edge; the slowest/fastest legal builds; pad/wind/conveyor transitions; rejected dodge and phase transition during a burst; wall/gate contact; supported soft fall and repeated respawn; camera at every stage boundary and extreme X.

## Stage 3 — inventory UI, HUD, animation and accessibility

Implemented:

- ItemDraft retains the offer until accepted result or authoritative closure. It sends exactly offerId/generation/itemId/replaceIndex or skip. At capacity, choosing a reward opens explicit replacement choices. Each shows the surrendered effect and resulting inscription counts against the shared threshold. Pending choices can be retried unchanged.
- CaptainSteveUI renders server-provided ownership, slots, upgrade/refund costs, canEquip/canUpgrade/canSmash and next-tier previews. It does not decide tiers or prices. Commands include generation, monotonic shared sequence and one GUID per deliberate click; retries retain the identical payload. Sequence is reconciled with shopSequence.
- Temporary read-only profile state is visible. The server may allow a temporary loadout but disables permanent purchases/smashing. Rejected actions show their reason; panels are not falsely dismissed.
- Shop opens only from server OpenShop after validated interaction. UI no longer interprets a local prompt trigger as purchase/loadout authorization.
- Reward/ending continuation waits for CommandResult or a stage transition; retry controls recover delayed acknowledgements. No timer silently advances the run.
- HUD starts its cooldown refresh from Init, receives boss identity/HP/maxHP/phase in snapshots, and converts deadlines using serverNow. It renders current persona, weapon, item capacity, turtle requirement and Sunburn.
- Incidental HUD cues are coalesced instead of inserting every combat event into the necessary dialogue queue. Damage labels are capped at 18 active instances, non-query/non-touch, and stop drifting in ReduceMotion.
- UiKit provides clamped responsive panels, wrapped text, scrolling, 44–48 pixel controls, safe inset use, controller selection and Activated handlers. LargeText updates existing UiKit text rather than waiting for a new panel.
- Options offer all visual controls, text speed, clear controls, ReplayTutorial and explicit ReturnToHub recovery. Returning during an active run requires a deliberate second click labeled as ending that run.
- AnimController caches rig motors/base poses once per character, ignores same-persona updates, loads/falls back per clip, uses the server Animator, and sets explicit locomotion/action priorities. Default Animate supplies locomotion when no authored clip is available; procedural action offsets are restored each frame and on teardown. It rechecks character identity after waiting for an Animator.
- All eight personas have registry bags and distinct procedural action pose parameters. Missing, invalid or not-yet-loaded clips use the procedural action fallback; no invented asset IDs were added.
- EquipmentController displays a local welded, non-colliding weapon silhouette by family. VFX use deliberate melee/ranged/thrown/shield/wave families with a fallback, no claim of 28 distinct authored animations.
- AccessibilityController adds per-viewer, surface-relative danger stripes and a DANGER label. It does not move/resize the server attack volume. Reduced motion disables ambient emitters and reduces/removes optional player motion/flashes without changing gameplay.
- ArtAssets validates imported presentation templates before cloning: a root, reviewed schema/orientation, finite bounded geometry and instance/part budgets; executable/audio/remote or competing-motion instances are rejected. Invalid templates keep the procedural kit. Clone collision/query/touch flags are cleared; the server factory explicitly establishes the authoritative collider.

Source audit performed after this stage:

- Replaced nullable module-global GUI construction with local typed instances. Fixed the queue table.remove optional result instead of suppressing strict typing.
- Removed the copied rarity order/cost preview rule from UI; server now provides the preview fields.
- Fixed old shop response/retry handling across hub generations and ensured the same payload is retained for retry.
- Fixed danger stripes initially using independent anchored parts that would not follow a moving/reused volume; switched to SurfaceGui patterns.
- Fixed repeated particle destruction callback registration during settings refresh.
- Added explicit imported-model contract checks; notified world/factory owner to normalize enemy colliders and use PivotTo for imported Steve.
- Verified no empty exported client function stubs remain. Hold controls use InputBegan/InputEnded by design; their generic Activated callback is intentionally absent of a second press action.
- Compiler/type review was run sequentially by root. At validation-03/04 the only client errors were the optional table.remove result in Tagline; that guard has now been added. The final root validation pass supersedes that intermediate result.

## Responsibility ownership after implementation

| Concern | Owner | Client responsibility |
|---|---|---|
| Accepted actions, phase, health, cooldowns | Server combat/session snapshot | Send bounded intent; predict feedback; display accepted state |
| Inventory eligibility, offered membership, grant/replacement, set activation | Draft/domain services and shared definitions | Display offered/owned data and a prospective inscription count; send selection |
| Ownership, upgrade tier/cost, refund, persistent profile permission | Hub/Meta services | Render provided fields, preserve retry identity, show result |
| Tutorial completion and campaign facts | Server tutorial/story/progression | Queue readable text; no client progression acknowledgement rule |
| Hazard identity/volume/damage and motion contribution | Server hazard/combat services | Consume explicit motion contract; add per-viewer patterns |
| Character locomotion integration | MovementController under server movement validation | One local integrator; reset from authoritative revisions |
| Audio policy | Fixed experience policy, default override, template validation | Suppress sound; expose no audio preference |
| Art import acceptance | Shared reviewed asset contract; factory owns collider | Animation/visual fallback; no gameplay selected by a visual key |
| UI focus/modal state | PresentationState/UiKit | Affect local intent dispatch only; never grant server permissions |
| Provider credentials, persistence writes, entitlement/security decisions | Server/adapters | No client provider credentials or authorization logic introduced |

This is a source ownership confirmation, not a claim that exploit resistance or engine behavior has been fully exercised.

## Visual content coverage and remaining proof

| Family | Implemented representation | Remaining acceptance |
|---|---|---|
| Eight personas | Existing server look plus cached per-persona procedural action poses; per-clip registry fallback | R15 silhouettes, anticipation/contact/recovery at actual camera distance; empty/partial/denied/complete clip registry |
| 28 weapons | Catalog selection, owned-state display, equipped family silhouette, family VFX | Weapon-to-family readability and attachment placement; all unlock/use paths in engine |
| Enemies/bosses | Existing procedural rigs/world ownership; server owner improved cached animation/volumes | Every shape at distance, phase tells, collider alignment and death/telegraph cleanup |
| Hazards | Authoritative geometry with local stripes/labels | Moving/pooling volume, colorblind contrast, jump-avoidance readability, source-enabled emitters while ReduceMotion is on |
| Stage palettes/props/pickups | Existing procedural world and new root/world changes | All-stage screenshots, foot placement, route visibility and performance |
| Required dialogue | Small queued bubbles, run scope, notes history | Short landscape/portrait, long words, Unicode, fast campaign transitions |
| Draft/shop/options/HUD | Clamped scroll panels, complete commands, boss/cooldown state, live text size | Minimum phone viewport, controller focus navigation, touch hit targets, long translated strings |

Imported mesh/animation manifests remain intentionally empty of real uploaded payloads/IDs. No external asset load or animation permission success is claimed. No engine screenshot or FPS claim is inferred from reduced source size. The remaining work is empirical acceptance and defects found there, not reopening the removed audio pipeline.


## Final integration pass

Root reported validation-05 client compiler/type checks clean. Subsequent integration reconciles whitelisted settings from authoritative snapshots after both accepted and rejected SyncSettings commands. Open option labels listen to their attributes and disconnect when destroyed, preventing an optimistic rate-limited toggle from remaining visually wrong. ClientReady now includes the initial keyboard/touch/gamepad cohort; changing devices does not resend a stage-resetting handshake. Root added Scriptable default computer/touch movement settings and server CommandResult for newspaper/ending continuations. Later validation folders supersede validation-05 where applicable.

Root reported validation-07 fully passing (compiler, Roblox types, contracts, seven domain suites, Rojo package and stable hashes). Final readiness wiring now also requires state.characterReady before enabling intent or dismissing the initial loading screen; that two-condition integration change should be covered by the next root validation/build. Story summaries and ending lines use the same required-beat priority so they preserve trigger order across a fast continuation. Source is now frozen for engine checks except for defects found there.

## Per-catalog visual inspection matrix (rendering unverified)

Every row below is source coverage, not a captured render. All rows still require framing, silhouette, contact/feet, facing, animation and smallest-device checks. Enemy dimensions are catalog baselines; procedural builders may reshape the root. buildGeneric dispatch contains shape branches, so its name does not by itself mean a plain placeholder.

### All weapon entries

| Weapon | Held representation | Decorative cue key | Render status |
|---|---|---|---|
| BareHands | No prop; fists | punch | Unverified |
| FlipFlopSlap | Flat slap/bash panel | slap | Unverified |
| LawnDart | Flat thrown-prop family | dart | Unverified |
| GolfClub | Long melee-prop family fallback | swing | Unverified |
| GatorWrestleGloves | Long melee-prop family fallback | grab | Unverified |
| RomanCandle | Short barrel family | firework | Unverified |
| SnakeLasso | Flat thrown-prop family | lasso | Unverified |
| SpillSkimmer | Long melee-prop family fallback | splash | Unverified |
| PoolNoodle | Long melee-prop family fallback | bonk | Unverified |
| CoolerLid | Flat slap/bash panel | bash | Unverified |
| BeachUmbrella | Long melee-prop family fallback | thrust | Unverified |
| FireExtinguisher | Short barrel family | foam | Unverified |
| TrafficCone | Flat thrown-prop family | cone | Unverified |
| KayakPaddle | Long melee-prop family fallback | paddle | Unverified |
| BugZapper | Long melee-prop family fallback | zap | Unverified |
| WaterBalloonSling | Short barrel family | balloon | Unverified |
| ShoppingCart | Long melee-prop family fallback | ram | Unverified |
| PelicanBeakReplica | Long melee-prop family fallback | peck | Unverified |
| OilBarrelLid | Flat thrown-prop family | disc | Unverified |
| TikiTorch | Long melee-prop family fallback | torch | Unverified |
| Skateboard | Flat slap/bash panel | board | Unverified |
| FishSmack | Long melee-prop family fallback | fish | Unverified |
| NewspaperRoll | Long melee-prop family fallback | paper | Unverified |
| NetGun | Short barrel family | net | Unverified |
| SludgeHose | Short barrel family | hose | Unverified |
| FinaleRocket | Flat thrown-prop family | rocket | Unverified |
| HOAClipboard | Long melee-prop family fallback | clip | Unverified |
| BoogieBoard | Flat slap/bash panel | board | Unverified |

The shared families are honest fallbacks, not 28 bespoke weapon models. Highest-value visual follow-ups after engine capture: gloves should read as gloves, cart as cart, fish as fish, and cone/dart/lasso as distinct thrown tools; then compare the remaining long-prop variants. Their catalog name/equip selection remains exact.

### All enemy and allied catalog entries

| Entry | Shape / behavior | Catalog baseline XYZ | Presentation builder | Render status |
|---|---|---|---|---|
| BeachCrab | crab / scuttle | 3.2, 1.6, 3.2 | buildCrab | Unverified |
| HermitCrab | crab / tank | 2.8, 2.2, 2.8 | buildCrab | Unverified |
| SandFlea | hopper / hopper | 1.6, 1.2, 1.6 | buildGeneric(shape branch) | Unverified |
| CrabKingBoss | crab / scuttle | 5.5, 3, 5.5 | buildCrab | Unverified |
| AngryTourist | humanoid / chase | 2.4, 5, 2 | buildHumanoidish | Unverified |
| SelfieZombie | humanoid / spitter | 2.2, 4.8, 2 | buildHumanoidish | Unverified |
| CondoKaren | humanoid / spitter | 2.5, 5.1, 2.1 | buildHumanoidish | Unverified |
| SlushieSlime | slime / puddle | 3.5, 2.5, 3.5 | buildSlime | Unverified |
| HotDogCart | cart / charger | 4, 3, 2.5 | buildGeneric(shape branch) | Unverified |
| SlushieKing | slime / puddle | 5, 5, 5 | buildSlime | Unverified |
| HOAHydra | boss / summoner | 6, 5, 4 | buildBoss | Unverified |
| DriveThruGator | gator / tank | 7, 3.2, 3.5 | buildGator | Unverified |
| Cottonmouth | snake / chase | 4, 1.2, 1.2 | buildSnake | Unverified |
| BurrowSnake | snake / burrower | 3.5, 1.0, 1.0 | buildSnake | Unverified |
| OilGator | gator / puddle | 6, 2.8, 3 | buildGator | Unverified |
| FireLizard | lizard / firearc | 3.5, 2.2, 4 | buildLizard | Unverified |
| EmberSkink | lizard / firearc | 2.2, 1.4, 3 | buildLizard | Unverified |
| MutantAdd | lizard / chase | 3, 3, 3 | buildLizard | Unverified |
| SwampSummoner | humanoid / summoner | 3, 4.5, 3 | buildHumanoidish | Unverified |
| PelicanBully | pelican / charger | 3.5, 3.5, 3 | buildGeneric(shape branch) | Unverified |
| MosquitoCloud | cloud / hopper | 4, 3, 4 | buildSlime | Unverified |
| JetSkiBandit | cart / charger | 4, 2.5, 2 | buildGeneric(shape branch) | Unverified |
| OilPuddleLayer | slime / puddle | 3, 2.5, 3 | buildSlime | Unverified |
| GulfGulpGrunt | humanoid / chase | 2.6, 5.2, 2.2 | buildHumanoidish | Unverified |
| DroneSpotter | drone / hopper | 2.5, 1.2, 2.5 | buildGeneric(shape branch) | Unverified |
| LabCoat | humanoid / spitter | 2.4, 5, 2 | buildHumanoidish | Unverified |
| RigWelder | humanoid / firearc | 2.8, 5.2, 2.4 | buildHumanoidish | Unverified |
| BarrelRoller | barrel / charger | 3, 3, 3 | buildGeneric(shape branch) | Unverified |
| RedTideBlob | slime / puddle | 4.5, 3, 4.5 | buildSlime | Unverified |
| OffshoreCrab | crab / scuttle | 4, 2, 4 | buildCrab | Unverified |
| StormPelican | pelican / hopper | 4, 3.5, 3.5 | buildGeneric(shape branch) | Unverified |
| RigOverlord | boss / firearc | 8, 7, 5 | buildBoss | Unverified |
| Spillfather | boss / tank | 12, 8, 6 | buildBoss | Unverified |
| RescueTurtle | turtle / chase | 2, 1.2, 2.4 | buildTurtle | Unverified |

Captain Steve is outside Enemies.List: WorldBuilder creates a procedural pelican kit or a validated imported kit. Verify beak/body silhouette, bonfire contrast, prompt height/range and no dialogue overlap; render remains unverified.



### All eight player personas

All rows share the server Animator, the default locomotion fallback, independent per-clip loading/fallback and a cached R15 motor baseline. Each has nine empty registry slots (Idle, Run, Jump, Attack1–3, Dodge, Skill, Swap). No uploaded clip success is claimed. The twist/arm/spread numbers describe procedural peak pose parameters; ReduceMotion scales optional pose amplitude to one quarter.

| Persona | Catalog color | Skill family | Twist / arm / spread degrees | Render status |
|---|---|---|---|---|
| BeachBurnout | Gold/orange | Wave | 22 / 70 / 30 | Unverified |
| CrabKing | Red/pale red | Dash | −28 / 42 / 62 | Unverified |
| GatorHauler | Green/dark green | AOE | 12 / 100 / 28 | Unverified |
| SnakeCharmer | Light green/green | Summon | −18 / 48 / 44 | Unverified |
| GolfCartBandit | Cyan/blue | Dash | 30 / 82 / 12 | Unverified |
| FireworksEnthusiast | Pink/yellow | AOE | 10 / 115 / 55 | Unverified |
| LizardBreath | Orange/yellow | Beam | −12 / 62 / 40 | Unverified |
| TurtlePaladin | Teal/pale green | Shield | 4 / 75 / 18 | Unverified |

Before accepting the pose matrix, capture each facing direction, weapon family, attack contact, jump apex, dodge, skill and swap with normal/reduced motion. Confirm default Animate does not cancel the intended procedural offsets and that no imported partial registry disables unrelated fallback clips. Alternate rigs are not declared visually supported by this report; test R15 first.

### Hazard presentation and motion consumers

The server owns all rules below. The client adds a surface-relative pattern and label when ColorblindTelegraphs is enabled, without changing the volume. Source coverage does not prove warning/active-phase contrast in a rendered scene.

| Hazard definition | Authoritative effect family | Presentation/movement consumer to inspect | Render status |
|---|---|---|---|
| oilSlick | Slow | Surface warning; published move speed | Unverified |
| sandSlow | Slow | Surface boundary vs decorative sand | Unverified |
| redTide | Slow | Red-tide boundary and safe beach distinction | Unverified |
| canalWater | Water + slow | Water edge, timeout/recovery message, pads | Unverified |
| slushPuddle | Periodic damage | Warning/active timing vs visible puddle | Unverified |
| fryerOil | Periodic oil damage | Fryer extent and oil-resistance feedback | Unverified |
| pipeSpray | Periodic oil damage + vertical impulse | Spray shape, ImpulseRevision/Y, recovery | Unverified |
| slickRing | Periodic oil damage | Ring shape vs damage volume at edge/center | Unverified |
| movingSample | Damage | Moving volume pattern follows Adornee | Unverified |
| fireCone | Damage | Fire cone/strip boundaries and no optional flash dependence | Unverified |
| hoaCone | Damage | Warning strip, paperwork cue, vertical avoidance | Unverified |
| conveyor | Horizontal motion | ExternalVelocityX contribution and exit edge | Unverified |
| windPush | Horizontal/downward motion | Nonaccumulating ExternalVelocityY, direction and overlap | Unverified |
| JumpPad (separate environment mechanic) | One-shot upward impulse | World pad marker; no repeated impulse on one revision | Unverified |

### Options and UI visual coverage

| Surface/option | Default or authoritative source | Current presentation consumers | Required visual test |
|---|---|---|---|
| Screen shake | On | Camera.Shake; bounded optional noise | Toggle during hit/boss cue; confirm no physics change |
| Patterned danger cues | Off | Local SurfaceGui stripes and DANGER labels | Two visual settings configurations; moving/reused hazard; color contrast |
| Reduce motion | Off | Camera focus/shake, procedural pose amplitude, ambient emitters, VFX and damage text | Camera/VFX/ambient behavior in a dense late stage |
| Reduce flashes | On | Optional hit spark and HUD punish flash | Confirm required danger is visible with flashes removed |
| Large text | Off | Existing/new UiKit labels/buttons gain 3 px | Small portrait/short landscape, long item/persona names, no truncated actions |
| Text speed | Normal (0.028 s/grapheme) | Required/optional dialogue reveal | Slow 0.055, normal, instant; reveal then advance exactly once |
| Notes / weapon list | Authoritative items/unlocks + accepted dialogue history | Scrollable inventory summary, direct weapon choice, story review | Controller focus, all 28 possible unlocked entries, newest dialogue visibility |
| Draft replacement | Server retained offer | Reward cards, lost effects, resulting inscriptions, retry | Full six-slot bag, long text, stale/duplicate response |
| Steve loadout/upgrade | Server shop catalog/profile status | Slot selection, costs/refunds/previews, read-only explanation | Two personas, duplicates, insufficient funds, temporary profile, delayed retry |
| Boss and cooldown HUD | Server boss/deadlines/serverNow | HP/phase label and running deadline display | All boss phases, post-death clear, device sizes, long boss name |
| Story/newspaper/ending | Scoped server text + retained completion state | Small bubbles and compact continuation cards | Required text never takes defensive input; final return waits for result |

The local Studio attempt was made by root after this source work. Root reported that free physical memory fell to roughly 188 MiB before a usable UI; only the worker-launched Studio process was closed, recovering about 1.5 GiB. Therefore no row above gains an engine-render pass from that attempt. This is a resource-limited verification gap, not an observed gameplay pass or failure.

