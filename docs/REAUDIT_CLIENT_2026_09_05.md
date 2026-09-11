# Client re-audit — 2026-09-05

Status update: the latest main09 static package passed 78 runtime source files, 15 behavioral suites and 112 checks; derived QA09 passed six separate checks. No 09 engine test was run. Root-observed matching08 evidence includes Hub Tab, Input.Intent walking/jump, native NPC E without relocation and a clean bounded client audio scan. Its startup dialogue-fragmentation defect is repaired/tested in 09 source; complete-conversation engine reading remains outstanding. Stage/lifecycle/Active-combat tests were not executed on 08 because commit headroom fell below 2 GiB. This worker did not perform the Studio actions. Original review locations below identify the stated source phase.

## Evidence and scope

The user reported that E did nothing at the bonfire and Captain Steve, and that the screen was “SUPER busy.” The root agent supplied the actual baseline [hub screenshot](reaudit-evidence-2026-09-05/baseline-hub.png) and the 02:26:26 CreatorError from the package opened in Studio, `artifacts/validation-07/FloridaMan.rbxlx`.

Initial and held first-pass SHA-256 hashes are saved in [client-source-hashes.json](reaudit-evidence-2026-09-05/client-source-hashes.json); the second-pass manifest is [client-second-pass-hashes.json](reaudit-evidence-2026-09-05/client-second-pass-hashes.json). The initial hashes identify the files read before these client changes. First-pass source locations below preserve the line references at that hold; second-pass locations are recorded in the appended implementation table. Old line numbers are not reconstructed from a newer file. Parent and other workers modify server, world, and tooling files independently; their runtime fixes and package proofs must be assessed against their own final report and build identity.

Scope: input ownership and gating; character setup, movement and camera; HUD/dialogue/menu hierarchy; equipment and action feedback; controller/touch focus; accessibility and silence; release-validation claims. Server startup, movement authority, world labels and lighting are root/other-worker ownership.

## Findings, fixes, and required runtime checks

### RC-01 — P0: observed startup failure prevents all proximity interactions (root-owned)

**Observed:** The supplied live log reports “Can only call Network Ownership API on a part that is descendent of Workspace” at baseline GameService.tryReady line 172. The old setup marked its character bound and disconnected its assembly listener before the unguarded ownership call; the exception prevented characterReady from becoming true. A nearby bonfire response consequently suggested moving beside the bonfire despite the avatar being at its spawn.

**Expected:** A fully assembled, Workspace-descended character becomes ready; pressing E beside a valid prompt runs exactly one accepted action. **Actual:** The exception leaves the readiness gate false and both start/NPC interactions unusable. This observed server failure is the main established cause of the user's E report. RC-02 is an additional input defect, not proof that input arbitration caused this particular live exception.

**Fix ownership:** Root is repairing event-driven assembly/ancestry readiness, ownership assignment and its recoverable failure path. Current GameService has guarded ownership code around lines 199–201; that source change alone is not live proof.

**Meaningful live regression:** Launch the exact newly identified package. From a cold player spawn, wait for visible readiness, press E once at the bonfire, return, press E once beside Steve, and close the shop. Record state generation, accepted action, characterReady and zero startup exceptions. Separately delay HRP/Humanoid insertion or parent the assembled character to Workspace late, then repeat without respawning.

### RC-02 — P1: interaction has competing key owners and a wrong controller key

**Source evidence:** The initial InputController (hash beginning b13d63af) bound interact in its high-priority ContextActionService action and called InputHoldBegin/InputHoldEnd while native ProximityPrompt still owned its key. Native prompts were left with their default controller X while the client also bound X to Attack and advertised LB for Use. This makes the displayed controller contract inconsistent and gives keyboard activation two owners.

**First-pass fix:** InputController.lua:169 assigns E and ButtonL1 to prompts, sets OneGlobally exclusivity, and no longer binds E/LB as a separate CAS gameplay action. InputController.lua:232 enables native prompts only when authoritative character/action state and local modal state permit interaction. Touch USE activates the same prompt rather than a separate server command. Nearest target lookup remains bounded to GameWorld and FM_Action prompts.

**Runtime check:** With keyboard and gamepad separately, enter/leave each prompt radius and press E/LB once. Count exactly one accepted start/shop action; X attacks in a run and never activates a prompt. While Steve/Draft is open, E/LB does not act through that panel. Test touch USE beside two near prompts and verify the displayed native prompt and touch-selected target agree. Native prompt arbitration and touch selection are not established by source compilation.

### RC-03 — P1: persistent UI obscures play and duplicates platform/world instructions

**Observed:** The baseline hub image has a broad 90–114 px HUD, a large persistent dialogue panel, default chat/player list over it, and overlapping world labels/native prompts. The dialogue and multiple always-visible instructions compete with the avatar and interactable. The original small-screen dialogue region also reaches the touch Jump region.

**First-pass fix:** HUD.lua:115 now creates one 44 px status strip, capped at 600 px wide, showing HP/bonfire plus one immediate objective and a menu button. Bag, currency, weapon descriptions and history live in Notes & equipment. Separate cue boxes and repeated cancel/punish popup text were removed. init.client.lua:14 hides duplicate Chat/PlayerList/Health/Backpack CoreGui with bounded retries while retaining the Roblox menu.

GameplayLayout.lua:5–15 is the numeric layout used by HUD and Tagline. Tagline.lua:50 measures actual Gotham text, wraps it into bounded pages, and reserves touch-control space. One small popup occupies at most 400×116 px (136 px with Large text) and the whole popup advances by tap, T or D-pad up. Reading time pauses while obscured by a menu. Essential lines auto-advance after a readable dwell and remain in Notes; this is an intentional presentation change, not loss of authored conversation. World label/lighting changes are owned elsewhere.

**Checks written:** tests/gameplay-layout.test.luau exercises the production layout on 24 width/height, Large text and touch combinations, checking HUD/dialogue/touch separation and viewport bounds. An extremely short viewport uses a zero-height popup rather than obstructing controls; queued text remains available for a usable viewport/Notes. This fallback is a limitation, not universal small-screen accessibility.

**Meaningful live regression:** Capture the same hub viewpoint at the baseline viewport after the new build. Verify avatar/nearby prompt stay legible, no duplicate Roblox HUD, only one dialogue popup, complete longest conversation in normal/Large text and Slow/Instant speed, and tap Jump/USE throughout on 320/360 px portrait and landscape touch emulation. Review actual font rendering and text clipping; rectangle tests cannot establish either.

### RC-04 — P1: menu stacking, hidden gameplay input, and draft focus loss

**Source evidence:** Initial HUD independently opened Options and Notes at the same display order without a shared modal owner. Gamepad stick input still drove movement while GUI focus was active. Initial ItemDraft.render destroyed the focused choice when entering full-bag replacement and did not focus a replacement button, leaving a controller user without a selected action.

**First-pass fix:** UiKit.lua:66 owns one panel; destruction clears its modal/focus state. UiKit.lua:111 adds Escape/B close for dismissible panels and deliberately preserves required Draft. ItemDraft.lua:46–53 explicitly focuses the first replacement. InputController clears held input when a modal opens and passes controller navigation while a GuiObject is selected.

**Audit after fix:** The new single-panel owner introduced a potential required-Draft replacement when O opened Options. This was caught before packaging. HUD.lua:29–34 and :64 now refuse to open Options/Notes while another panel owns focus or a draft is pending. Full options are allowed in Hub, Reward and Recovering. Opening Options cannot erase a required draft. Newspaper/Credits use their own small continuation bars and are not UiKit.Panel instances; Ending is excluded from Options.

**Meaningful live regression:** Using only controller, choose a reward with a full bag, navigate replacements/back/skip, submit and proceed. Press O/D-pad-left and B/Escape at each required choice; no required panel disappears and no item is awarded twice. Open/close Steve/Options/Notes repeatedly, then hold/release movement during transitions and confirm no stuck axis or movement behind a modal. Check that focused navigation does not also jump/swap.

### RC-05 — P1: local attack/dodge feedback claims unaccepted actions

**Source evidence:** Initial InputController computed attack combo using a start-time .45 s window while server combo logic used accepted recovery-end grace. Slow legal weapons could therefore show the wrong local combo. It played swing feedback before acceptance and never reconciled the accepted attack event. Initial dodge initiated the 18-stud burst before server acceptance; rejection could arrive after displacement.

**First-pass fix:** InputController.lua:122 plays the accepted combo/facing/weapon VFX and synchronizes readiness from the server event. init.client.lua:150 routes accepted attacks. InputController.lua:132 and init.client.lua:151 apply dodge only from the accepted event through MovementController.lua:88. Requests are bounded by a pending timer and accepted cooldown; no unaccepted dash is simulated. The server remains the action authority.

**Tradeoff:** Waiting for acceptance adds visible round-trip latency. That is preferable to reporting false success but still needs a responsiveness test. This worker did not measure network latency or dodge reach live.

**Meaningful live regression:** Equip the slowest legal attack setup and execute three legal attacks just after recovery, comparing server accepted combo and displayed pose. Deny attacks/dodges during recovery and confirm no full attack/dash plays. At low and simulated 150–250 ms latency, confirm one request gives one attack/dodge and accepted dodge distance stays inside the server envelope. Parent's movement-authority worker owns the separate legitimate-dodge envelope correction.

### RC-06 — P1: late character assembly permanently disables client movement/animation (source repaired; runtime pending)

**Exact first-pass evidence:** MovementController.lua:48–50 and AnimController.lua:84–90 waited five seconds for character parts then returned permanently; neither subscribed for later arrival for that character. AnimController also gave up waiting for Animator. A late replicated Humanoid/HRP could therefore pass the repaired server setup while the client remained unbound.

**Second-pass repair:** Per-character identity and coalesced DescendantAdded/DescendantRemoving/AncestryChanged watchers retry when required parts reach Workspace. Movement rebuilds its constraints only when root/Humanoid identity changes. Animation adopts a replicated Animator and late motors. Character removal disconnects that character's watchers and restores owned state. No competing local Animator is created.

**Meaningful live regression:** Insert HRP, Humanoid and Animator after the former timeout; movement, facing constraints and animation must initialize once without a respawn. Remove/replace a character repeatedly and count one controller constraint set and no stale callbacks.

### RC-07 — P2: procedural animation fallback omits locomotion and R6 joints (source repaired; runtime pending)

**Exact first-pass evidence:** ArtAssets.lua:72 publishes empty clip IDs. First-pass AnimController.lua:126–135 only attempted Idle/Run tracks; when absent no fallback walking-leg motion was generated. Action pose code at :141–150 used R15 names Waist/RightShoulder/LeftShoulder without R6 “Right Shoulder”/“Left Shoulder”/RootJoint aliases. Motors were cached only at initial bind. Stock Animate ownership was not explicitly resolved. This is a source-established gap in the promised fallback, not an observed live animation recording.

**Second-pass repair:** Added R6 aliases for root/shoulders/hips, late motor discovery, an idle breathing pose, opposite arm/leg run stride and rising/falling poses. Existing persona action poses remain the fallback for accepted actions. Stock Animate is disabled only after both shoulders and hips exist; its previous enabled state is restored during teardown. Reduced motion reduces cosmetic pose amplitude without changing simulation. Live rig articulation and track ownership still require the checks below.

**Meaningful live regression:** With empty animation IDs, record idle, left/right run, jump/fall/land, three attacks, dodge, skill and persona swap on R6 and R15. Arms/legs must articulate, feet should not merely slide, and action/idle tracks must not fight. Repeat Reduce motion and two respawns.

### RC-08 — P2: accessibility pattern calls inactive/non-damaging surfaces “DANGER” (source repaired; runtime pending)

**Exact first-pass evidence:** AccessibilityController.lua:16 accepted any Hazard attribute or attack marker, then :28–33 added an always-on-top “! DANGER” billboard. It did not observe HazardActive/HazardEnabled and used the same label for slowing/current surfaces as damage volumes. Particle reduction at :36–42 was applied only on inspection/settings changes; a later emitter Enabled=true was not observed.

**Second-pass repair:** Pure AccessibilityRules receives the actual shared hazard definition and classifies damage, directional flow and slow surfaces. Surface-only stripes, arrows and spaced marks replace the floating DANGER labels. Disabled hazards have no cue, and inactive damaging phases have no danger stripe. Attribute changes update active/enabled/type/direction and removal releases the local records. Reduce motion uses ParticleEmitter.LocalTransparencyModifier, preserving server Enabled/Emit state while hiding subsequent emissions. This avoids restoring stale Enabled state after toggling the option. tests/accessibility-rules.test.luau checks actual catalog classifications and enemy/unknown cases; it does not test rendering or event timing.

**Meaningful live regression:** Toggle patterned cues on a timed vent, inactive damage volume, wind/current/conveyor, and enemy windup. Only actual damaging phases use danger semantics; direction/control surfaces are distinguishable. Pool/reuse and toggle settings 20 times; no accumulated marker folders/connections. Emit a new particle effect after Reduce motion and verify suppression.

### RC-09 — P2: touch controls do not communicate disabled/cooldown state (source repaired; runtime pending)

**Exact first-pass evidence:** MobileControls.lua:30–49 always drew the same action labels and showed them whenever TouchEnabled plus Hub/Active phase was true. It did not distinguish last-used input device or reflect authoritative character readiness/action cooldown. HUD.lua:159 hid cooldown labels on any TouchEnabled device. A touch user therefore saw ready-looking controls that could not act, while a hybrid keyboard device could receive unnecessary touch overlays.

**Second-pass repair:** DevicePolicy.Cohort supplies one last-input policy to the handshake, HUD, dialogue reservation and MobileControls. Touch-only startup retains controls; a hybrid device uses its most recent keyboard/mouse/touch/gamepad input. Existing action buttons show a disabled mark, pending mark or accepted cooldown countdown using Input.ActionStatus. Movement/jump tint follows readiness. Hiding controls releases held touch input. tests/device-policy.test.luau checks seven production policy cases; target size and actual multi-touch remain live checks.

**Meaningful live regression:** On touch-only and hybrid devices, verify controls show when appropriate, become visibly unavailable before ready/in modal/on cooldown, and return on accepted readiness. Changing device must release held movement. Check ATK/SKILL/DODGE/SWAP/USE in Hub, Active, Reward and Recovering.

### RC-10 — P1: release checks were presented more strongly than their evidence supported (root-owned)

**Evidence:** The actual failing session opened validation-07 while later compile/type/pure-test package artifacts already existed. Previous passing checks could not establish that the user opened the intended binary, that character ownership APIs ran successfully in Workspace, or that native E prompt interaction worked. The live startup exception demonstrates that distinction directly.

**Implemented provenance repair:** Parent added scripts/build_identity.py so a package contains an immutable BuildIdentity derived from source hashes. HUD.lua:111 exposes this value in Options. Parent now performs a serial main validator/package run followed by an explicit live scenario probe. The isolated QA place remains separate from the default project and must be regenerated against a matching passing baseline, not presumed current after these edits.

**Acceptance:** The package SHA, embedded build identity, validator report, screenshot and live runtime log must identify the same build. Record each actual action/assertion, exception, unexecuted scenario and environmental blocker. A compile pass, pure layout test or headless stage-domain probe is not an E/UI/animation playtest.

## Additional review results and limitations

### RC-11 — P1: O menu shortcut loses to the default camera zoom action

**Observed in parent live package 03:** O failed in both Hub and Active while clicking the HUD menu opened it. The runtime log recorded “Action zoomOutAction is not handled” at both O attempts. This establishes a competing native action rather than merely uncertain focus timing.

**Source:** The first-pass HUD bound FM_Options with default ContextActionService priority, unlike the gameplay actions already at 3000. The next source binds FM_Options with BindActionAtPriority 3000. D-pad-left uses that same binding. Dialogue advance passes while a modal or text box owns input; swap passes while a modal disables gameplay so B can close its panel. The small combat-menu B/Escape close intentionally uses 4000.

**Runtime update:** Priority3000 did not resolve O in the main05-source Studio session. Main08 added Tab with O as alias; native Tab opened/closed Hub Options in matching QA08. Verify Active/Draft/Steve arbitration and D-pad-left on the next identified build; no native O success is claimed. Preserve the known Studio zoom conflict rather than rewriting this source repair as a passed O test.

- **No audio:** No new sound, narration, music or audio setting was added. SilenceController remains enabled before gameplay controllers, suppressing existing and subsequently added Sound/AudioPlayer instances and their play/volume changes. This source review does not measure audible output. Live validation should inspect all active audio sources while spawning/respawning and triggering every effect, without adding audio for feedback.
- **Small popup conversations:** Essential story text, NPC lines and gameplay tips use one bounded popup and are retained in Notes. Shop/draft controls are functional menus rather than conversation walls. Essential auto-advance timing is a changed interaction needing readability acceptance. Notes/Options are intentionally restricted to safe phases; the active run has a small “Run continues” menu with Close and a confirmed Return to bonfire path (HUD.lua:75), so abandoning a run remains accessible without silently pausing the world.
- **Camera:** Current CameraController uses a scriptable camera with bounded horizontal lag, per-frame root lookup, teleport/generation resets and reduced-motion focus/shake gates. No new deterministic defect was established in this pass. Portrait threat visibility, world-label overlap and camera/ground framing remain live visual checks.
- **Equipment:** EquipmentController observes WeaponId and late hand children and supports RightHand/Right Arm. All authored weapons still use a limited set of generic procedural shapes. BareHands repeats a harmless update on ChildAdded because the no-model state is not cached. Neither is treated as a proven E blocker.
- **Server authority:** Native prompt presentation is local; server distance/readiness/action validation must remain authoritative. This worker did not relax server gates or grant progress to make testing appear successful.

## Verification ledger

| Work | Evidence at first-pass hold | Status |
| --- | --- | --- |
| Baseline HUD/source inspection | supplied baseline-hub.png, live log described above, initial hashes | Performed |
| First client implementation and follow-up source audit | held hashes and exact current locations above | Performed |
| Production layout regression suite | tests/gameplay-layout.test.luau; parent reports all 10 suites passed in reaudit-build-01 | Passed in parent serial run |
| Compile, Roblox-aware type analysis, main package build | [Main09 report](../artifacts/reaudit-build-09/report.json): 78 runtime files, 15 suites, 112 checks. [QA09](../artifacts/reaudit-studio-09/report.json): six isolated checks | Static pipelines passed for immutable 09 artifacts. No 09 engine test; whole-conversation reading remains open |
| Post-fix bonfire E and run UI |03 bonfire E, accepted Shift and confirmed Return;05 NPC E/Close after relocation;08 Hub Tab and native NPC E after Input.Intent approach | Root-observed scoped passes.08 approach used no location teleport; native held movement keys, Active Tab, required-modal and device matrix open |
| Native Space jump | [05 events](reaudit-evidence-2026-09-05/build05-engine-events.txt):1,794 samples/29.994905s, Y 4.176333→11.499826→4.176333, rise 7.323493,resets=0,commands=[] | Observed native jump/return.08 Input.Intent short-release jump separately rose 6.362633 and landed. Same-build held/released comparison and device/rig matrix open |
| Client08 movement/audio diagnostics | [08 events](reaudit-evidence-2026-09-05/build08-engine-events.txt): deltaX 6.610567, jump landed,1.53s, stable motion revision; audio 2,342 nodes/no sources/no truncation | Real Input.Intent composition and bounded client silence scope observed. Hub combat unavailable/not attempted; native held-key and whole-campaign silence not established |
| Client08 dialogue integrity | Read preserved “retry.” at 376px width;08 eagerly paginated before viewport readiness | Observed failure. Main09 source and production pagination tests passed; actual repaired reading remains unexecuted |
| Controller/touch, delayed assembly, animation, accessibility regressions | second-pass implementation plus detailed scenario checks above | Source/rule checks passed in main09; actual device/rig scenarios remain unexecuted |
| Published/live-player release | none | Not performed |

Update this ledger only with actual matching-build evidence. “Source repaired” does not mean runtime regression passed.

Post-hold correction: the first validation identified a mixed string/number cooldown tuple at HUD.lua:161. This was replaced with typed addCooldown calls; the obsolete Movement.dodgeReady field/setter and two caller writes were removed. The recorded firstPass hashes intentionally identify the pre-type-correction hold; the parent validator's next immutable hash manifest identifies the corrected package.

Second-pass source locations: MovementController.bind at :47 and CharacterRemoving at :121; AnimController aliases at :93, late assembly at :94, stock ownership at :115 and locomotion fallback at :176; AccessibilityRules.Cue at :5 and AccessibilityController visibility/attribute lifecycle at :52–81; DevicePolicy.Cohort at :3, Input.ActionStatus at :47 and MobileControls visibility/countdowns at :50–65; small build identity at HUD.lua:113.

Parent live package 03 feedback established that the hamburger glyph rendered as a missing glyph. The next source uses plain “O” on the menu button. The O-key failure was subsequently traced to zoomOutAction; see RC-11. The HUD now displays “Collect the Cold One” when the root-exposed coldOneRequired is true and coldOneTaken is false, after higher-priority boss/rescue status. A source lifecycle audit also added an early current-character guard before either client binder tears down existing state, preventing a stale deferred initial bind from invalidating a newer character.

Build 04 type follow-up: the shared HazardDef.slow field changed from boolean to the categories oil/environment during the concurrent server pass. AccessibilityRules now matches that contract. AccessibilityController uses an explicit numeric particle baseline and a freshly typed Marker after checking the existing record, eliminating optional-value inference errors. No behavior was bypassed and no blanket type suppression was added. The afterLiveFeedback hash set predates this narrow correction; the next validator manifest binds the corrected files.

Latest runtime/tooling addendum: QA08 build/report and subsequent engine evidence are separate. [Structured runtime records](reaudit-evidence-2026-09-05/runtime-results.json) preserve 13 records including truncated logs. The isolated client Read/ScanAudio/MovementSmoke endpoint was actually invoked; it is absent from the default project and uses no development network remote. MovementSmoke's Hub ok=true did not attempt attack/skill/dodge: allActionsAccepted=false, intentSubmitted=false and unavailable-no-intent. No Active-combat success is inferred.

QA08 hit 1.45–1.61 GiB commit headroom, below the 2 GiB host threshold. Stage/lifecycle/Active smoke was not executed; the root closed its own Studio. Idle headroom recovered to about 5 GiB, but one play session had consumed roughly 3.5 GiB, so this remains a real acceptance constraint. Security [source coverage](REAUDIT_SECURITY_COVERAGE_2026_09_05.md) is sealed at 07:00:27 UTC: 138 full current-path receipts, including 112 authoritative files/78 runtime and 22 retired scripts. No additional reportable finding was established; runtime/storage/deployment/device guarantees remain outside that source conclusion. Main09 dialogue and final README versions were verified. Visual comparisons have unequal viewports and do not constitute final art/readability approval. See [QA instructions](../qa/README.md) and the [consolidated ledger](REAUDIT_2026_09_05.md).

### RC-12 — P1: startup viewport permanently fragments necessary conversation

**Observed in matching main08/QA08:** QA_CLIENT_READ at 06:40:05 preserved the Progress popup body as only “retry.” although its content rectangle was376px wide and 62px tall. The full line is marked truncated in the evidence record; the preserved body/rectangle and subsequent text measurement are sufficient for this specific finding, not for unrecorded GUI claims.

**Source cause at the 08 review state:** Tagline.lua:33–36 uses CurrentCamera.ViewportSize without waiting for nonzero usable dimensions. chunks at:44–51 then measures using max(50, area.width−24). Tagline.Show at:151–156 splits the incoming complete message immediately and stores each chunk independently in queue/history. An initial zero viewport therefore permanently chooses 50px pages; later resize can only reflow those fragments. Viewport geometry belongs to presentation time, while the queue/history must own the complete accepted content.

**Repair included in main09:** Tagline retains each original accepted message and one complete history entry. It waits for usable viewport/insets and actual text dimensions, then delegates page selection to pure DialoguePagination. Grapheme byte offsets preserve all text and reflow the current unacknowledged page on size changes; only advance consumes text. Priority, generation cleanup, readable dwell and hidden/menu-paused timing remain owned by Tagline. No audio or larger persistent overlay was added.

**Static verification:** Main09 compiled/typechecked and passed the new production dialogue-pagination suite (15 suites total). Its cases exercise page reflow, full text reconstruction, word/whitespace handling and grapheme boundaries including clusters too large to fit. Tests pass explicit grapheme fixtures and a pure fit predicate; they do not certify Roblox TextService sizing, viewport startup or rendered readability.

**Runtime verification still required:** Cold-boot the identified 09 package and read complete startup, Steve, objective and finale conversations at normal/Large size and Slow/Instant speed. Resize while unrevealed/revealed, advance pages, open/close menus and verify complete Notes entries without lost/duplicated/orphaned words. QA08 proves the original defect, while09 provides source/rule evidence only. No 09 Studio was launched under the resource stop.
