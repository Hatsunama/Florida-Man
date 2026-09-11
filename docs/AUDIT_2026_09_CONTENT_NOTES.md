# Content, presentation, story, options, and balance audit notes

Audit date: 2026-09-04 ET. Source snapshot: `1bff8c516fd0dfed08f991e0c23c008c665f707d`.

This is the content/presentation workstream of the full audit. Evidence is source inspection and catalog enumeration, not a Roblox Studio playtest. Runtime consequences below describe what the inspected code would do once the separately discovered HazardService parse failure is repaired. No assets or gameplay source were changed. P1 = substantial broken behavior or release requirement; P2 = material usability/maintainability/content gap; P3 = cleanup. Exact line numbers refer to the source snapshot. Related server authority findings have been shared with the other audit workstreams.

The current user requirement is **NO AUDIO, and every necessary conversation in SMALL POPUP TEXT**. Earlier documents permitted combat sounds, ambience, and optional UI clicks. That older allowance is superseded. Silence is a product requirement, not an audio-quality defect.

## Inventory and coverage

| Catalog/surface | Count and current implementation | Coverage result |
|---|---|---|
| Stages | 21 definitions: one hub and 20 playable stages, five acts | All stage definitions, verb routing, world generation and story delivery inspected |
| Enemies | 34 definitions: 33 hostile types and one rescue ally | All 33 hostile IDs occur directly in stage waves/miniboss/boss fields; RescueTurtle is spawned separately. Enemy mechanics detailed in gameplay audit |
| Personas | Eight definitions, three-hit moveset data for all eight | Unlock/equip connectivity, skills, authored/procedural animation inspected |
| Weapons | 28: 18 melee, five ranged, five thrown | All IDs appear in starter state or stage unlock map; finale acquisition has a bypass caveat. Fourteen weapons use the same generic local slash fallback |
| Items | 28: HUMID 5, FERAL 4, LUCKY 2, GREASY 5, HEROIC 6, CHAOS 6 | Stat computation, specials, draft and set connectivity inspected; **zero of six sets can be reached under current slot caps** |
| Art | Two Markdown files under `assets/`; no authored mesh/image/animation payloads there | Part/SpecialMesh fallback is real; imported assets remain absent, not delivered |
| Animation registry | Four of eight personas have registry bags; nine empty clip strings in each (36 empty entries) | Zero nonempty authored clips; current registry + player only support fallback |
| UI | HUD, Steve, newspaper, draft, tagline, credits, mobile, loading | All eight modules inspected |
| Options | Six booleans plus text speed (seven preferences) | Implemented but incomplete across UI/particles/telegraphs; some controls have layout/feedback problems |
| Audio | 15 SFX catalog entries and 12 biome beds across six keys | Actively played; violates current silence requirement |
| Story | Five act bibles, 20 stage headlines, five act openers, five midgate lines, nine verb hints, three Act 1 event lines, five death lines, credits | Content exists, but delivery overwrites, repeats, spoils, or bypasses parts of it |

## High-priority findings

### C01 — P1: the game actively plays audio despite the explicit silent-product requirement

**Evidence:** `src/client/init.client.lua:36` starts AudioDirector unconditionally. `src/shared/Settings.lua:20` defaults MuteMaster to false. `src/client/Controllers/AudioDirector.lua:112`, `:145`, `:157`, `:173`, `:195`, `:221`, and `:249` retain one-shots and looping beds; only two dialogue SFX names are blocked. `src/server/WorldBuilder.lua:1301–1325` creates 15 SFX and two bed Sound objects for each stage. `src/client/UI/ItemDraft.lua:47–50`, `Newspaper.lua:197–200`, and `Credits.lua:121–125` request UI/credits sounds. Loading and credits explicitly promise optional SFX.

**Scenario:** A fresh player receives ambience immediately and combat/draft/credits sounds afterward. Merely defaulting MuteMaster to true would still permit turning audio on and would leave sound creation and playback paths active. Roblox default character sounds also need an explicit engine-side audit; these source modules do not establish global silence.

**Owner/fix:** Product policy in one shared immutable presentation policy; client presentation owns enforcement. Remove/decommission AudioDirector activation, PlaySound event use, stage audio creation, sound options, and obsolete audio recommendations. Audit built-in character/ambient/default sounds at startup and respawn. Replace audio-dependent narrative cues with visible collar lights and small popup text.

**Verification:** A fresh session, saved-settings session, respawn, each action, every biome, draft, newspaper, boss intro and credits produce zero audible output. Capture/assert no game-owned Sound enters Playing state; separately check engine-provided character sounds. No option can re-enable audio. Add a silence regression check; do not retain an old dialogue-only check as sufficient evidence.

### C02 — P1: slot caps make all six inscription sets impossible and stop build growth almost immediately

**Evidence:** `src/shared/Constants.lua:21–24`: first-run slots = 1, later slots = 2, set size = 3. `src/server/RunContext.lua:170`, `src/server/HubService.lua:40`, and all other itemSlots assignments only choose 1 or 2. `RunContext.lua:334` and `DraftService.lua:44–49` enforce the cap and skip later drafts. `HUD.lua:662` still advertises progress toward 3; `ItemDraft.lua:70` tells players three matching items unlock a set.

**Scenario:** A first-run HermitCrab drop can consume the only slot before the first draft. If no enemy drop does so, the first chosen item locks the build for the remaining 19 stages. After one death, the maximum is two items. HUMID, FERAL, LUCKY, GREASY, HEROIC and CHAOS never activate. GREASY resistance and HEROIC lifesteal implementations are dead through ordinary play. One-time healing food permanently occupies a precious slot. Luck on the final available item has little or no subsequent draft benefit.

**Owner/fix:** Progression/inventory service and balance design. Choose a viable maximum inventory size at least compatible with intended sets, add clear slot growth or make sets attainable at actual caps, and support replacement/discard/decline when full. Resolve whether food is consumed or equippable. Add a reward-choice transaction so random enemy drops cannot silently lock a build. Preserve variety throughout the 20-stage campaign.

**Verification:** Reach every set through legitimate play; complete a first run and a repeat run with multiple meaningful choices in each act. Exercise duplicate items, full slots, enemy drops, declining and replacement. Simulate least-lucky and most-lucky builds against every act; ensure the player can keep shaping the build after Act 1.

### C03 — P1: unlocked personas do not have a player-controlled equip path

**Evidence:** `RunContext.lua:308–325` auto-fills slot 2 only if fewer than two personas are equipped. `HubService.lua:50–56` resets to BeachBurnout plus the first key encountered in the unlocked dictionary. `CaptainSteveUI.lua:75–146` offers only Upgrade and Smash. No EquipPersona remote, slot picker or equivalent exists. `HubService.lua:116–141` removes an equipped persona when smashed, despite a toast that tells the player to unequip first.

**Scenario:** The first run acquires CrabKing in stage 1 and keeps BeachBurnout/CrabKing. Later GatorHauler, GolfCartBandit, SnakeCharmer, LizardBreath and TurtlePaladin unlock but cannot be selected that run. Subsequent runs choose an unspecified dictionary-order second persona. Players cannot reliably use an upgraded favorite without destructively removing alternatives. Paying to upgrade an inactive persona may yield no usable improvement.

**Owner/fix:** Loadout/progression service owns two validated persona IDs; UI displays a selectable roster with equip-to-slot actions. Keep destruction separate from equipping, show active slots, sort roster deterministically, retain selected loadout across runs, and make unlock notification actionable.

**Verification:** Legitimately unlock each of eight personas, equip into each allowed slot, swap during combat, reject locked/duplicate/invalid IDs server-side, and rejoin with the intended loadout. An upgrade must show its actual attack/skill/cooldown benefit on a selectable persona.

### C04 — P1: camera deadzone arithmetic adds absolute positions instead of interpolating them

**Evidence:** `src/client/Controllers/CameraController.lua:124–127` computes `oldFocus + 0.15 * excess + 0.85 * focusX`. For lookPos.X=108 and player X=106, oldFocus=100, excess=2.5, and the target is **190.475**, not near 106. Translating the identical configuration by +100 changes the target by +185, so the rule is not translation-invariant. `:28–34` integrates a spring using raw frame dt.

**Scenario:** Leaving the deadzone can send the camera target far ahead, especially later in a positive-X level. The spring can recover from the small stationary example. The parent's [moving-player scalar trace](audit-evidence-2026-09-04/camera-math.json) nevertheless demonstrates sustained divergence: at 60 Hz, starting X=400, moving at 18 studs/second for three seconds and stopping for two leaves a look-position error of about 2,278 studs. This is mathematical execution of the current equations, not an observed Studio camera trace.

**Owner/fix:** Camera presentation controller. Calculate deadzone excess in relative coordinates, interpolate with weights summing to one, clamp to stage bounds, reset springs at teleports, and use a stable dt/substep strategy.

**Verification:** Mathematical translation-invariance test plus continuous walks at stage X=18/100/250, left/right reversals, 15/30/60/120 FPS and a large hitch. Keep player and immediate threat visible with no artificial forward jumps.

### C05 — P1: essential story popups disable combat while enemies remain active

**Evidence:** `InputController.lua:25–35` treats FM_Tagline as blocking; `:191–254` blocks keyboard/gamepad attacks, skills and swaps while it exists. `Tagline.lua:95` waits 4.5 seconds after full reveal; slow typewriter adds more time. `StageFlowService.lua:492–516` shows a MidGate story popup at the same time it locks a room and spawns enemies. The server encounter is not paused. MovementController maintains a separate enable gate rather than sharing this modal state.

**Scenario:** Enter a first MidGate in an act: dialogue appears, attacks and skill/swap stop responding, and the newly spawned wave can still attack. Touch skill/dodge paths bypass parts of InputController, so devices behave differently. This is a gameplay penalty for receiving narrative.

**Owner/fix:** A client UI coordinator should classify small story bubbles as nonmodal and reserve modal locks for actual choices. If dialogue is deliberately blocking, the authoritative encounter must enter an explicit safe state. Small necessary conversations should not consume combat input; use a specific dismiss control rather than global movement/action keys.

**Verification:** Trigger every scripted line while moving, attacking, dodging, swapping and taking damage. Combat remains usable during nonmodal text on keyboard/gamepad/touch. Modal transitions pause or safely gate the encounter in one place.

### C06 — P1: core progression UI is fixed-width and loses content on phone viewports

**Evidence:** `Newspaper.lua:47–48` is 680×520 pixels; `ItemDraft.lua:76–77` places three 200×260 cards across a 640-pixel span; `CaptainSteveUI.lua:34–35` is 520×420; `Credits.lua:69–70` is a 720-pixel-wide holder. `HUD.lua:198–199` places a 360×480 options panel at y=56. Its seven 48-pixel rows plus a 44-pixel Close and seven 8-pixel gaps total 436 pixels inside a 410-pixel list, so Close overflows the panel even at desktop sizes. No viewport-driven responsive layout/scrolling is provided for these surfaces.

**Scenario:** At 375-pixel portrait width, side draft cards and newspaper text extend offscreen. On a short landscape phone, draft cards extend below the bottom and the options Close/text-speed controls are inaccessible. Large story cards also violate the requested small-popup conversation format.

**Owner/fix:** UI layout layer. Use safe insets, viewport constraints and responsive stacking/scrolling; preserve readable font minimums and touch target sizes. Convert required newspaper/Steve story text into compact anchored bubbles with a separate optional journal. Fit choices in a mobile carousel or vertical list, with all choices reviewable before commit.

**Verification:** Full run progression and every setting at 360×640, 375×812, 640×360, 768×1024 and desktop sizes, including safe areas and text scaling. No necessary text/button offscreen; no combat button overlap; no forced unreadably small type.

### C07 — P1: finale success bypasses the story's rescue requirement and misreports the rescued count

**Evidence:** `Stages.lua` finale requires three turtles; `StageFlowService.lua:270–276` checks them in FinishStage, but `:209–215` calls FinishRun 1.2 seconds after Spillfather's death directly. `:346–370` has no rescue/completion guard and displays `Turtles rescued forever: s.turtlesRescued`; `:104–105` resets that counter at each stage. The previous turtle stages contain five plus four rescues, so a full honest campaign is twelve, not the finale's local 0–3. FinishRun also schedules hub return after two seconds while credits scroll for 28 seconds.

**Scenario:** Defeat the boss before finishing the final rescues: credits claim the turtles are safe anyway. FinaleRocket is only granted in FinishStage's weapon table (`:309`), so this common direct FinishRun path skips its unlock. Hidden hub gameplay can resume behind credits.

**Owner/fix:** Run/stage completion service. One idempotent completion predicate must require boss defeated, final rescue complete and any other intended conditions. Track run and lifetime rescue totals separately. Grant finale rewards in the sole completion transaction, then show small closing conversations and optional credits; resume hub when the presentation flow is acknowledged or safely completed.

**Verification:** Boss-first, turtle-first, simultaneous last kill/rescue, reentrant callbacks and early credits dismissal yield exactly one completion/reward and the correct 12-run-rescue total. FinaleRocket is obtainable through the normal completion path.

### C08 — P1/P2: authored animation readiness is overstated; state updates stop all tracks, and partial uploads disable fallbacks

**Evidence:** `init.client.lua:58–60` calls SetPersona on every StateUpdate, including every accepted attack (`AttackService.lua:175`). `AnimController.lua:195–199` clears/stops all tracks even when the ID is unchanged. `:304–306` runs procedural fallback only if Attack1 has no syntactically valid ID, regardless of whether other clips are missing or failed to load. `:83` assigns Action priority to every clip, including Idle/Run, and the airborne branch does not stop Idle/Run (`:293–301`). `:266–269` merely adds an attribute to default Animate; it does not disable or coordinate it.

**Scenario:** Once real clips are uploaded, attack acknowledgments stop the locally played attack. Uploading only Attack1 disables procedural Dodge/Skill/Swap/other attack fallback. A syntactically plausible but unavailable Attack1 can leave attacks unanimated. Uploaded locomotion may overlap with default Animate and action clips. Today there are no authored clips to mask these integration defects.

**Owner/fix:** Animation controller should change persona only when ID differs, manage one track state machine with proper priorities and explicit locomotion transitions, and select fallback independently for each failed/missing clip. Cache only successful loads and use asset-load readiness evidence, not string plausibility, as the playback result.

**Verification:** Fully empty registry, Attack1-only upload, missing permission, missing asset, full clip pack, repeated identical StateUpdate, attacks during swap/jump, death/respawn and ReduceMotion. Record that the intended action track survives server acknowledgment and all absent clips receive a fallback.

## Additional actionable findings

| ID / severity | Evidence, scenario, actual consequence | Correct owner, action, verification |
|---|---|---|
| C09 / P1 | `MobileControls.lua:51–77` has ATK/SKILL/DASH/USE/WPN and **no SWAP**. Swap exists only on Q/gamepad B (`InputController.lua:205`, `:232`). Touch players cannot use the dual-persona core action. | Input action registry + touch adapter. Add the same Swap action and cooldown state to touch; verify every gameplay action is available on all supported devices. |
| C10 / P2 | `HUD.lua:670–675` starts its cooldown loop while the module is being required, before `HUD.Init()` assigns gui. `task.spawn` starts immediately; `while gui and gui.Parent` is false, so countdowns update only on StateUpdate. BossBar at `:309–332` starts invisible and has no later update code. | HUD controller lifecycle and explicit boss-state view model. Start refresh after Init and dispose correctly; subscribe to active boss HP/phase. Verify skill countdown progresses while idle and boss bar shows, updates and clears on all encounter transitions. |
| C11 / P1/P2 | `HUD.Toast:478–492` is one replaceable label. `StageFlowService.lua:156–157` fires ActOpener then RestToast in the same callback, guaranteeing the opener is overwritten immediately; `:164`, `:173` overwrite again within a second. `Tagline.lua:12–15` destroys the previous conversation. Delayed stage/hub messages have no stage/run-generation checks (`StageFlowService.lua:79`, `:129`, `:155`, `:163`, `:178`). | Dialogue/message coordinator with typed priority, queue, dedupe, optional history and stage-generation cancellation. Coalesce routine combat messages; keep objectives readable. Verify new stage, death, prompt spam and simultaneous unlock/drop cannot erase essential lines or deliver obsolete-stage dialogue. |
| C12 / P2 | `Story.lua:186–193` chooses the same Steve line for an entire act based only on death count; 20 lines exist but a deathless run receives only the first of each act. Repeated mutant tagline is scheduled in many stages despite the Act 2 bible saying "once, then escalate". All three act-wide panels are shown after every stage (`StageFlowService.lua:338`), revealing late-act information early. `Story.lua:27`, `:142–143` asks the player to listen/hear clues in a now-silent product. | Narrative state/definition layer. Stage/event-specific line IDs, seen-state and reveal prerequisites; small text bubbles that describe visible collar blinking. Verify a deathless run advances through unique beats without premature lab/finale spoilers or audio-dependent clues. |
| C13 / P2 | `Tagline.lua:24`, `:57–63` allocates only 58px of body at fixed 22px text inside 72% viewport width. Longer lines exceed this on small screens. `:114–121` slices UTF-8 text by bytes; em dashes, ellipses and other non-ASCII characters are revealed in broken intermediate sequences. `:149–163` treats Space as skip while movement separately treats it as jump. | Popup renderer: grapheme-aware reveal (`MaxVisibleGraphemes` or equivalent), adaptive height with a small maximum footprint, user-controlled timing/history and one explicit dismiss action. Verify long strings, emoji/accents, instant/slow speed, keyboard jump, touch and gamepad. |
| C14 / P2 | `AttackService.lua:27–35` uses **weapon.vfx** to enable +45% foam damage and net rooting. A presentation-key rename changes gameplay. `isFireEnemy:18–24` duplicates classification via behavior and literal enemy IDs. | Shared typed weapon/enemy mechanics data; server combat effect dispatch. Separate effect IDs/tags from presentation.vfx. Verify changing only visual identifiers/colors does not change damage, root duration or eligibility. |
| C15 / P2 | `WorldBuilder.lua:261–344` embeds hazard damage, periods, duty cycles, slow amounts, conveyor push and wind rules in art construction attributes. `_BuildGround:976–1025` mixes difficulty and traversal generation with rendering; floor segment shrinkage is not compensated to ensure exit coverage. | Shared HazardDef/StageLayout rules + server layout/hazard services; WorldBuilder renders an already-valid layout. Build all 20 seeded collision layouts and prove an exit/checkpoint route for starter and slowest persona. Ground extent concern remains static until actual Random-based layout is enumerated. |
| C16 / P2 | `EnemyService.lua:620–636` enables colorblind styling for **everyone** when any player's preference is on. It creates a Texture named CB_Stripe but never assigns Texture content. Changing Material to DiamondPlate is the only guaranteed visual change. | Server transmits semantic hazard type/shape/timing; each client renders its own accessible visuals. Use visible pattern geometry/icons/labels independent of hue. Verify two clients with opposite preferences and multiple telegraph types, including empty-texture failure. |
| C17 / P2 | `Settings` ReduceMotion is consumed by Camera/Anim/some VFX, but `HUD.lua:508–518` still full-screen flashes; Newspaper/ItemDraft/Credits always animate; `VFX.SwingSlash` still moves large neon objects; WorldBuilder/EnemyFactory particles are not preference-controlled. `CameraController.Focus` still shifts framing. | Client presentation policy applied at all effect call sites, not gameplay authority. Add independent flash reduction and text-size controls if useful; honor reduced motion for UI and background particles without hiding semantic telegraphs. Verify every surface/action and toggling during an active effect. |
| C18 / P2 | `WorldBuilder.lua:841–847` nests CaptainSteve under CaptainSteveModel, while `InputController.lua:105–106` uses direct-child `world:FindFirstChild("CaptainSteve")`. Manual/gamepad tryInteract cannot find him. The normal ProximityPrompt can still work; mobile USE fires StartRun and Talk together and never opens Steve UI (`MobileControls.lua:69–72`). | Single interactable registry/adapter, with explicit target action and server acceptance event opening shop. Verify E, clickable prompt, gamepad L1 and touch USE perform the same intended action, including overlapping bonfire/Steve ranges. |
| C19 / P2 | `CameraController.lua:50–70` only clears arena lock on arenaUnlock. `init.client.lua:StageLoaded` does not reset camera, and LoadHub sends no StageLoaded. Death during locked MidGate can leave later hub/stage framing biased toward the old room. | Camera controller receives stage/run lifecycle reset and teleports with zero stale velocity/focus. Verify death/reset/disconnect during lock, stage transition during focus, and respawn. |
| C20 / P2 | `TutorialController.lua:report` stores lifetime local flags; HubService.StartRun resets server TutorialFlags each run. Mobile/gamepad jump are not reported by the keyboard Space handler; movement teleports can count as movement. `GameService.lua:198–200` records any reported dodge after attack as a successful telegraph dodge without validating danger/avoidance. | Server tutorial truth from accepted actions/actual outcomes, client prompts as presentation. Synchronize tutorial session/version and device labels. Verify out-of-order actions, second run, death, touch/gamepad jump and dodge outside any telegraph. |
| C21 / P2 | `LoadingGui.lua:100` fades at fixed 1.4s, unrelated to world/character/UI readiness. Its art is GuiImagePlaceholder, and `:80` exposes "Soft launch N8 · InEngine_v3" to players. Credits expose implementation/policy text (`StageFlowService.lua:361–362`) instead of story. | Boot readiness coordinator + presentation copy. Hide splash after minimum readable display time and required readiness, with a visible failure state; remove internal implementation labels from player copy. Verify slow load, missing world/character and normal boot. |
| C22 / P2 | `VFX.lua:110–157` returns for all ranged/thrown kinds, making later dedicated `elseif kind == "dart"` and `"firework"` blocks unreachable. Fourteen weapon definitions use the same default slash. Player appearance in `RunContext.ApplyPersonaLook:217–265` is BodyColors + Highlight, with no equipped weapon visual. | VFX/character presentation. Remove unreachable branches and choose a bounded set of intentional readable silhouettes, held-tool/impact shapes and distinct projectile tells; do not claim 28 unique visuals just from catalog names. Verify a contact sheet/video for all 28 weapons and eight personas. |
| C23 / P2 | `CaptainSteveUI.lua:60` shows no upgrade costs, next rarity, complete benefit, affordability or smash return before clicking; closes after fixed 0.2s (`:116`, `:139`) regardless of acknowledgment. Starter Smash is presented even though server rejects it. State changes do not update an already-open panel. | Hub view model sourced from authoritative economy rules. Show price/result/current loadout, disable impossible actions, await accepted/rejected result, keep panel current and distinguish Equip from Smash. Verify all currencies/rarities, rapid clicks and delayed responses. |
| C24 / P2 | `docs/ART_PIPELINE.md` documents LOD budgets, but no LOD switch/culling implementation exists in EnemyFactory/WorldBuilder/VFX. `ArtAssets.IsValidAssetId` only rejects malformed/obvious IDs, not missing/wrong-type/unpermitted assets. `assets/` contains no delivered meshes/textures/sprites; 36 animation slots are empty. | Art pipeline plus release validation. Treat procedural kits as an explicit art choice; budget/profile them. Add a manifest of actual owned assets, load tests, fallback tests and visual approval. Do not upgrade asset readiness grade based on an upload hook alone. |
| C25 / P2 | `GameService.lua:294` calls ApplyCharacterSpeed for every player every 0.05s; `RunContext.lua:305` calls ApplyPersonaLook each time. That repeatedly scans/rewrites BodyColors, Highlight, persona and weapon attributes even in the hub and when nothing changed. `AnimController.applyProcedural:120–123` recursively searches four motors every RenderStepped. | Separate stat/appearance updates; cache rig bindings, recompute on relevant state changes and reserve frame work for animation transforms. Verify no unchanged look updates across idle seconds, correct swap/weapon/settings/respawn invalidation, and measure allocations/CPU on low-end devices. |
| C26 / P2 | `Newspaper.lua:193` always says "CONTINUE → ITEM DRAFT" even when DraftService skips full inventory. `HUD.lua:581`, `:588` says Swap/Skill Ready based only on cooldown, including hub/locked UI/only one persona. `HUD.lua:118–119` weapon-cycle button overlaps skill label at `:148–155` and is only 24px tall. | Presentation receives action availability and next transition from authoritative state, with device-specific hints and proper layout. Verify full inventory, one persona, hub, waiting-on-server and all inputs. |
| C27 / P2 | `DraftService.lua:69` offers three items but does not save offered IDs; `:94` only checks item is in the catalog. This makes advertised randomized rarity/choices forgeable. | Server draft transaction stores offer ID, allowed items, stage/run generation and resolution. UI sends only the chosen offer entry. Verify nonoffered Legendary item rejected, stale/replayed offers rejected and a legitimate selection resolves once. Server audit also owns this finding. |

## Complete stage differentiation review

Definitions are in `src/shared/Stages.lua`; geometry is in `WorldBuilder._SetPiece`, `_BuildGround`, `_Platforms`, and `_MidRoomGate`. A distinct setPiece string is not proof that a traversal/fight plays differently. All stages still share a linear progress-triggered wave loop and common mid-room gate system. The table distinguishes real wiring from remaining design/verification work.

| # / stage | Length / scripted waves | Wired identity | Required improvement or proof |
|---|---|---|---|
| 0 Hub | 70 / 0 | Bonfire, Steve, headline board | Repair nested Steve lookup, choose loadout, inspect upgrades, silent useful onboarding |
| 1 DaytonaHangover | 200 / 3 + CrabKing | Hangover, Cold One, collapsingPier | Cold One recovery and boss teaching are real; pier parts are static, so do not imply actual collapse. Prevent early drop consuming only reward slot |
| 2 BoardwalkChaos | 220 / 5 | FryerOil timed hazards, tourists/cart | Show hot/cool state with visual timing and meaningful safe intervals; stage entry hints must survive message queue |
| 3 GasStationLegends | 230 / 4 + SlushieKing | Neon canopy, slush hazards, MidGate | First lock must not disable attacks through dialogue; GolfCart unlock must become selectable |
| 4 StripMallShowdown | 230 / 4 + HOAHydra | Parking arena, HOA cones | Mechanically differentiate aura/citations and arena space from prior miniboss; test hazard readability |
| 5 DriveThruDisaster | 240 / 4 + DriveThruGator | Drive-thru lane, collar clue | Make collar reveal visible/silent and make GatorHauler usable after unlock |
| 6 CanalRun | 250 / 5 | Canal pads + water timeout | Prove pad route, water counter/reset and gap reachability for speed15 persona; enemies must respect the intended topology |
| 7 SwampShift | 280 / 6 | Cypress canopy, oil/fire mix | Distinguish from stage8 beyond enemy roster/palette; Lizard/Snake unlocks need selectable loadout |
| 8 CypressCathedral | 260 / 5 | Same cypressCanopy, summoner/burrowers | A second cypress stage needs a new encounter constraint/route, not only more waves; remove soundtrack-dependent story description |
| 9 SludgeBayou | 260 / 5 | Sludge flats, oil/fire | Make oil-resistance build achievable; telegraph how puddles and fire combine |
| 10 ConspiracyShack | 250 / 5 | Corkboard shack, labs/pelicans | Evidence currently appears as text/decor; use a brief visible discovery and earned clue bubble |
| 11 TurtleBeach | 260 / 5 / 5 turtles | Turtle nests, rescue escort, red tide | Escort is optional because prompt rescue works immediately; decide if escort is required or rename objective honestly |
| 12 NestGuard | 250 / 4 / 4 turtles | Same turtleNests, night/drones | Add a new rescue condition or route; do not repeat stage11 with fewer turtles and colors only |
| 13 GulfGulpGate | 270 / 5 | Corporate gate + generic added conveyors | Establish conveyor state clearly; no auth mechanics are represented by decorative badge signs |
| 14 LabWing | 270 / 6 | Conveyor samples + pipe spray | Strongest facility-specific interaction wiring; prove moving sample hit/collision/timing and show lab reveal after discovery |
| 15 PipeGauntlet | 280 / 5 + RigOverlord | Pipe platforms/spray + conveyors | Prove route and miniboss footprint coexist; avoid below-platform/invisible hitboxes |
| 16 LoadingDock | 260 / 5 | Dock/crane + generic conveyors | Distinguish from stage13 with a clear new spatial/encounter constraint |
| 17 BargeCrossing | 270 / 5 | Deck gaps, checkpoints, wind | Verify actual gap geometry is not covered by generic floor/deck parts; checkpoint lies on recoverable surface |
| 18 OilPlatformApproach | 280 / 6 | Rig lights + oil/fire + conveyors | Label says facility conveyor despite offshore biome; decide authored identity instead of default act fallback |
| 19 HelipadHysteria | 250 / 6 | Helipad wind | Balance opposing jumps; provide a visible recoverable approach to finale, not an abrupt gust soft-fall loop |
| 20 GulfGulpRig | 320 / 5 + Spillfather / 3 turtles | Boss phases + slick ring | One completion transaction must include rescues; validate all-phase positioning, boss bar, final reward and closing popup text |

Act-level claims need correction: Act 2's pad-only traversal is principally stage6, with stages7–10 using oil; Act 4 contains both generic conveyors and offshore wind/gaps. Act 5 consists of the boss stage, whose LevelVerb is bossArena rather than windGaps. These may be good choices, but "five unique act verbs" is not a substitute for twenty successful authored encounters. Generic floor shrinks on random gap segments and all platforms stop around 77% of stage length; automated actual-seed walkable-interval checks should precede additional art.

## Complete persona and ability review

| Persona | Current damage / speed / skill | Connectivity or honesty issue |
|---|---|---|
| BeachBurnout | Attack12, attackSpeed1, move18; wave28/5s | Skill says cone, implementation is front-facing X-distance test rather than cone/lane volume |
| CrabKing | Attack14, .95, move16; dash36/6s | "stun + big pinch" uses common hit flinch and instantaneous translation, not a bespoke forward claw/stun duration |
| GatorHauler | Attack16, .85, move15; AOE42/7s | AOE exists; physical grab/toss is not implemented; later unlock lacks equip path |
| SnakeCharmer | Attack11, 1.15, move19; summon30/8s | Lingering hitbox exists, not a friendly modeled coil creature; only generic presentation; later unlock lacks equip path |
| GolfCartBandit | Attack10, 1.25, move22; dash24/5.5s | Skill description promises multi-hit scrape but `SkillService.lua:104–127` teleports once and hits each nearby enemy once; armor frames are real |
| FireworksEnthusiast | Attack13, 1.05, move17; AOE38/7.5s | UnlockHint says chaos drafting/smashing (`Personas.lua:123`), but actual unlock is FinishRun; rockets are an AOE effect rather than multiple projectiles |
| LizardBreath | Attack15, .9, move17; beam40/6.5s | +40% versus OilGator is real; no general sludge armor system to melt; beam uses only forward X distance |
| TurtlePaladin | Attack14, .9, move15; shield18/9s | Heals18 + shield48 are real; catalog skillDamage18 not used as a damage/counter strike; no counterattack implementation |

All eight have distinct moveset scalar tables in CombatService, but only BeachBurnout and CrabKing have distinct procedural attack poses. ArtAssets contains empty bags only for BeachBurnout, CrabKing, GatorHauler and SnakeCharmer; add the other four before claiming complete clip integration. Rarity applies to damage and skill cooldown, but TurtlePaladin healing/absorb do not scale with rarity; a Legendary shield purchase is mostly CDR/basic-attack power, which the shop does not explain.

## Complete weapon review

All 28 IDs are present in starter/unlock data; stages automatically equip each newly granted ID, so a stage with two rewards silently ends on the last one, regardless of player preference. Basic attacks use persona moveset × weapon scalar. All ranged attacks share a two-hit projectile; thrown attacks use a single-hit lob. Only foam and net add weapon-specific combat effects. `vfx` is currently incorrectly used to choose those mechanics.

| Weapon | Kind / local effect | Behavioral truth |
|---|---|---|
| BareHands | melee / punch | Starter short burst; no held prop needed |
| FlipFlopSlap | melee / slap | Distinct local flop visual; starter unlock already true |
| LawnDart | thrown / shared lob | Real thrown projectile; later dedicated DartArc branch is dead |
| GolfClub | melee / generic | Range/scalar difference only; no held club |
| GatorWrestleGloves | melee / grab visual | No grappling mechanic |
| RomanCandle | ranged / shared trail | Flat projectile; later multi-color firework branch is dead |
| SnakeLasso | thrown / shared lob | No lasso pull/capture |
| SpillSkimmer | melee / generic | No independent oil-absorption mechanic |
| PoolNoodle | melee / generic | Long range/high speed scalar only |
| CoolerLid | melee / bash | Bash presentation; no blocking/shield state |
| BeachUmbrella | melee / generic | No actual thrust geometry distinction beyond scalar range |
| FireExtinguisher | ranged / shared trail | +45% vs classified fire enemies; not a foam cone volume |
| TrafficCone | thrown / shared lob | Single-target lob |
| KayakPaddle | melee / generic | Scalar-only melee; no double-ended special |
| BugZapper | melee / generic | No electric status/chain effect |
| WaterBalloonSling | ranged / shared trail | "Splash damage" flavor has no AoE projectile explosion |
| ShoppingCart | melee / generic | High knockback/slow scalar; no held/ridden cart |
| PelicanBeakReplica | melee / generic | Scalar-only melee |
| OilBarrelLid | thrown / shared lob | No ricochet/return behavior |
| TikiTorch | melee / generic | No burning status |
| Skateboard | melee / generic | Fast scalar; no grind/mobility interaction |
| FishSmack | melee / generic | Scalar-only melee |
| NewspaperRoll | melee / generic | Fast scalar-only melee; not automatically paper-cut item effect |
| NetGun | ranged / shared trail | Real root on nonboss targets; does not rescue turtles |
| SludgeHose | ranged / shared trail | Projectile, not sustained hose stream |
| FinaleRocket | thrown / shared lob | No large explosion AoE; normal boss-death completion can bypass its reward |
| HOAClipboard | melee / generic | Does not automatically apply paper-cut/citation mechanics |
| BoogieBoard | melee / generic | No surf movement |

These differences do not require 28 unrelated subsystems. A feasible improvement is 6–8 intentional behavior families with accurate copy, distinct silhouettes, clear range/tempo/secondary-effect tradeoffs, and all 28 variants mapped explicitly. Do not implement every humorous flavor literally; remove concrete mechanical promises that are not delivered.

## Complete item review

Flat damageBonus is converted into `damageMult += bonus / 20` (`RunContext.lua:102`), so +5 means +25% base attack/skill damage, not +5 final damage. HUD/draft should show the actual resulting stat change. `TryGrantItem:339–345` and `DraftService:102–107` heal before recomputing increased max HP; an item offering max HP and healing at full health can waste its advertised heal.

| Item | What actually applies | Correction/decision needed |
|---|---|---|
| FlipFlops | +2 move, .05 dodge-CDR | StatText omits CDR |
| CrackedVisor | +15 HP | Honest simple stat item |
| LiveBait | +15% damage + AggroPull distance bias | Aggro description needs meaningful tradeoff/readable effect |
| ExpiredSunscreen | +20 HP, -1 move | Honest tradeoff; route must remain traversable |
| IHeartFLShirt | +10 HP, .08 luck | Luck loses draft value after slots fill |
| NoveltyMug | +5 HP +20 heal/stage | Permanent sustain substantially stronger than one-use food under cap |
| TurtleSticker | +10% damage + unconditional .08 damageMult, heal5 | "corp tax" isn't target-specific; all enemies receive extra damage |
| GasStationTaquito | Heal25 once | Permanently consumes slot for exhausted effect; decide consumable policy |
| LawnDartCharm | +25% damage | Say percent/result instead of vague damage |
| HOACitation | +35% damage, .05 luck, crit chance | Real paperCut proc; show chance/multiplier and balance against common items |
| LuckyPenny | .15 luck | No damage/survival; often dead choice when it fills last slot |
| GatorSkinWallet | +20% damage, .05 luck, Sunburn-on-kill | Real economy effect; clarify future-run value and persistence |
| RadioCollar | +5 HP, +15% damage, 1.35 multiplier vs OilGator | Actual target-specific special; copy mostly accurate |
| SpillAbsorbent | +15 HP, .05 dodge-CDR, flat incoming-damage reduction | Absorb applies broadly, not only oil spit; reconcile copy/policy |
| LabBadge | +25 total HP, +40% total damage, +1 move, .1 luck | Hidden extra +5HP/.1 damageMult from badge special; no entitlement/auth rule implied |
| SeashellShield | +18 HP, .03 dodge-CDR | Says knock resist, but no knock-resistance effect |
| MosquitoNet | +5 HP, +1 move, .08 dodge-CDR | StatText omits HP/speed |
| PelicanWhistle | .12 luck, +10% damage | No audible whistle required; keep item fantasy visual/text |
| MustardPacket | +20% damage + heal8 | Healing before new max stats is a general grant-order concern |
| RedTideFilter | +22 HP + broad absorb reduction | "+HP vs blobs" is misleading; HP is unconditional |
| CondoPass | +3 move, .1 luck, .04 dodge-CDR | CDR omitted from copy |
| JetSkiKey | +4 move, +5% damage, .06 dodge-CDR | Useful speed choice; stage gaps/wind need verification with both speed extremes |
| CypressCharm | +8 HP, +10% damage | Honest basic hybrid |
| BonfireEmber | +25% passive damage, .02 dodge-CDR, +25% damage for2.5s after dodge | N3 implementation now real; do not repeat old audit claiming special empty |
| TurtleSnack | Heal20 once, .05 luck | No actual turtle empathy behavior; decide consumable versus permanent item |
| OilProofBoots | +12 HP, +2 move, .05 dodge-CDR, broad absorb | Boots do not grant the GREASY set's oil slow resistance alone; "slick floors hate these" overpromises |
| HeadlinePressPass | +10 HP, +40% damage, +1 move, .15 luck, paperCut | Strong multi-stat item; cannot validate balance without usable late-act draft choices |
| DewKoozie | +10 HP, heal12 once, +20 heal/stage | Initial heal happens before max HP increase; permanent sustain is real |

Set data exists and is partly wired: HUMID HP/CDR; FERAL +12% additive damage; LUCKY +.2 luck; GREASY HP/oil resistance; HEROIC on-hit healing; CHAOS +8% additive damage. None are reachable now. After fixing slot caps, LUCKY has only two unique item IDs; either duplicates must be an explicit supported set-building strategy, lower its threshold, or add a third LUCKY item. Current drafts can offer duplicates across successive offers because they rebuild the whole catalog pool.

## Layer responsibility confirmation

| Concern | Appropriate owner | Actual assessment |
|---|---|---|
| Catalog IDs/names/typed stat and effect definitions | Shared immutable domain data | Mostly suitable. Avoid assigning mechanics to `vfx`; centralize all effect definitions |
| Story strings and reveal prerequisites | Shared narrative definitions; server/run events decide unlock/reveal | Strings centralized, but stage code sends raw duplicated strings and many unscoped delayed callbacks |
| Damage/effects/unlocks/inventory/economy/completion | Server domain services | Source is server-owned, but effects and final-state transitions have missing contracts and cross-service duplication |
| Generated traversable layout and hazard truth | Server stage-layout/hazard services from typed definitions | WorldBuilder mixes geometry/art with hazard tuning and traversal validity; visual construction shouldn't silently decide balance |
| Appearance, animation, sound policy enforcement, per-player a11y | Client presentation | Player tint/Highlight repeatedly authored server-side; telegraph accessibility is globally decided in EnemyService; AudioDirector violates new policy |
| Local input prediction and presentation | Controllers with one action/modal coordinator | UI name checks and mobile direct remotes disagree; tutorial guesses success from input rather than outcome |
| Per-player preference storage | Server profile; client can optimistically display harmless preference | Settings' shared mutation helpers are not automatically an auth/security leak. These booleans are accessibility settings, not entitlements. Add schema/view-model boundaries for maintainability without inventing nonexistent paid authorization rules |
| Real asset availability/readiness | Asset pipeline + runtime loader + release gate | ArtAssets syntax check is not availability/ownership/permission validation; upload hooks and empty data do not constitute shipped art |
| Provider/auth/entitlement or AI memory/control policy | Only if such systems exist | No such systems were found in this content workstream. Do not label the in-fiction LabBadge as real authorization logic or infer unrelated policies |

Sharing a utility module between server and client is not by itself a violation. The concrete risks are **who can decide runtime outcomes**, whether rendering-key edits alter outcomes, whether UI independently owns modal/action truth, and whether authoritative state has one lifecycle.

## Prior audit corrections

- `AUDIT_N0`/`N3` correctly show the old over-cap insertion was closed, but missed that the resulting hard cap makes the inscription system and most subsequent drafts unreachable.
- `AUDIT_N3`'s all-weapons unlock-map coverage is syntactically true; it did not prove FinaleRocket's normal completion path reaches that table.
- `AUDIT_N4` correctly added seven settings; it did not prove layout, complete ReduceMotion coverage, per-player telegraphs, or current global silence.
- `AUDIT_N5` labeled a player being able to describe act differences PASS with an asterisk while no playtester ran. That is static wiring evidence, not a passed human acceptance test.
- `AUDIT_N7` honestly deferred actual uploads, but "pipeline live" skipped same-persona track destruction, partial-upload fallback and load-permission failure behavior.
- `AUDIT_N8`/`AUDIT_PLAN_NEXT_FINAL` call code soft-launch ready using source greps while Studio, live saves, external player completion, telemetry and device budgets remain deferred. Readiness cannot be concluded from these checks, especially given the new compiler failure and regressions above.
- The older full-system audit's audio F grade and plan for licensed score are obsolete under the new requirement. Remove audio improvement work from the next plan.
- Several earlier defects are now fixed and must not be re-reported as open: BonfireEmber has an ember hook, weapon cycling is wired, ranged pierce is capped, OilSlow is consumed, Types has actual structures, and GameService has been split. Remaining failure modes require fresh specific evidence rather than recycling the old god-object list.

## Feasible improvement plan and acceptance gates

### 1. Restore a trustworthy playable baseline

Compile all Luau first, then exercise module initialization and one complete hub-to-stage1 loop. Fix camera arithmetic, global world/run ownership, authority validation, lifecycle invalidation and other P0/P1 findings from the main audit before visual expansion. Establish a small reproducible test harness for pure logic plus actual Studio smoke traces. Grep assertions remain supplementary. Record failures and deferred checks honestly.

Gate: no parse/runtime bootstrap errors; player can see, move, attack, interact, die and restart on every supported input device without another player's run mutating theirs.

### 2. Make the experience silent and popup-driven

Remove active audio infrastructure and audio options; verify default engine sounds. Implement a small reusable bottom/side popup with speaker label, short readable text, explicit advance, queue priorities, dedupe, grapheme-safe typewriter, text-speed preference and optional journal/history. Keep necessary conversation nonmodal. Move newspaper story content into this system; retain larger newspaper art only as optional review. Remove implementation status labels from player flows and replace audible narrative clues with visible evidence.

Gate: all acts comprehensible with zero sound; no required line lost to a later toast; no dialogue disables necessary combat; long text fits on phone and can be reviewed.

### 3. Rebuild reward and loadout connections before retuning numbers

Define an explicit inventory capacity/growth model that supports sets. Add full-inventory replace/decline, explain temporary food, store draft offers on server, and keep meaningful rewards into later acts. Implement two selectable persona slots; show unlocks, upgrades, costs and outcomes, and retain loadout selection. Grant finale rewards through the same checked completion state.

Gate: every persona/weapon/item/set has a legitimate acquisition-and-use scenario. Generate a reachability matrix, not just catalog-ID reference checks. Prove rare items and Legendary upgrades influence actual playable loadouts.

### 4. Balance actual combat and recovery loops

Generate balance tables from the same data/functions as runtime: attacks per combo cycle, DPS over real recovery/cancel limits, effective range, knockback, skill cadence, received damage, survival time, heal resources, boss phase time, and reward availability. Include fresh-player one-run baseline, after-death upgrades, minimum-luck, maximum-luck and intentional high-skill play. Avoid using the stale sheet's 36–48 starter DPS assumption when current three-hit recovery is .16+.18+.26 seconds and damage multipliers sum to3.38; ideal no-latency base combo DPS is 12*3.38/.60 = **67.6** before hitstop/rate/input constraints. That is a model ceiling, not measured player DPS.

Gate: all 20 stages are completable with documented reasonable low-power builds, while strong builds feel better without invalidating telegraphs. Rarity and each weapon family have clear tradeoffs. All tooltip promises match computed outcomes.

### 5. Validate every stage's actual traversal and authored identity

Generate collision interval/height maps for exact stage seeds, then solve/check paths for the slowest persona, starter jump, upgraded movement and wind/conveyor conditions. Check checkpoints, terminal gaps, midgate, boss arena and turtle goals against actual geometry. Author encounter scripts using typed room definitions; choose one primary introduced/recombined mechanic per stage. Give stages7/8,11/12,13/16,18/19 distinct objectives or encounter constraints. Avoid adding length solely by adding similar waves.

Gate: no unreachable exit or soft-fall loop, no requirement contradicted by an alternate route, and uncoached players can name a gameplay difference for each neighboring stage pair. Mark the player-test gate pending until actual playtest evidence exists.

### 6. Finish readable character and weapon presentation

Keep the procedural style if it is the intended visual direction. First fix rig lifecycle/track handling and cache motors. Create an explicit silhouette/pose specification for all eight personas and 6–8 weapon families, with held props where appropriate. Generate a contact sheet from actual runtime frames covering idle/move/jump/attack/dodge/swap/skill, all enemy families, each stage landmark and all HUD states. Replace placeholder UI images with intentional icons. If imported assets are chosen, upload real owned assets and verify permissions/type/loading/fallbacks rather than adding plausible-looking IDs.

Gate: actions read without sound, team members can distinguish ally/enemy/interactive/hazard at gameplay scale, and every supported asset-failure path remains playable. No image/mesh quality claim without a viewed runtime artifact.

### 7. Complete options, input parity and responsive UI

Drive keyboard/gamepad/touch from a single action registry; add Swap on mobile, unify Use target selection, show device-appropriate labels and establish deterministic focus/dismiss behavior. Give all choice/shop/options screens safe responsive layouts. Implement complete reduced motion/flash policies, text-size support and per-player telegraph shape/pattern cues. Start/stop HUD refresh correctly and show boss/cooldown/action-availability state accurately.

Gate: the entire campaign and settings are operable without a mouse, without sound, on phone portrait/landscape and with accessibility options enabled. No game UI relies only on color to indicate lethal timing.

### 8. Profile, document and release on evidence

Separate layout truth from visuals; stop reapplying unchanged appearance every20Hz; cache rig/world references; budget particles, Parts, draw calls and UI updates; pool only measured high-churn effects. Implement LOD only where measurement shows value. Refresh player-facing documentation and technical ownership maps around actual behavior. Maintain one current finding ledger; prior audit documents remain historical evidence, not conflicting truth. Capture Studio/mobile frame times, low-memory behavior, full playthrough, published rejoin saves and human feedback before increasing exposure.

Gate: measured target-device frame-time/memory/network budgets, verified data persistence, full 20-stage run and repeat-run matrix, all P1 fixed or explicitly accepted with evidence, no stale "PASS" for unperformed human/device tests, and a fully silent release candidate.

## What this workstream did not claim

No actual Studio/mobile screenshots, audio capture, imported asset playback, real DataStore/provider verification, path solve using Roblox Random, human playtest or performance profile was completed here. Geometry extent, gamepad focus/activation, builtin character audio, partial uploaded animation behavior and device rendering require those follow-up checks. The source-backed defects above are actionable regardless; presentation quality grades should wait for visual evidence.
