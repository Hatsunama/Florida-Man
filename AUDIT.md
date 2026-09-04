# Florida Man — P0 Quality Audit

**Date:** 2026-09-04 (America/New_York)  
**Scope:** Movement feel, crab Motor6D assembly, combat swing snappiness  
**Repo:** `Hatsunama/Florida-Man`

## Confirmed P0 findings (pre-fix)

### Movement (`src/client/Controllers/MovementController.lua`)

| # | Bug | Effect |
|---|-----|--------|
| 1 | Every `RenderStepped` wrote full `hrp.CFrame` **and** `AssemblyLinearVelocity` | Fought physics → jitter / glitchy walk |
| 2 | No server `SetNetworkOwner(player)` on character HRP | Server simulation overwrote client velocity → rubber-banding |
| 3 | Extra custom gravity (`GRAVITY * 0.35`) stacked on `workspace.Gravity` | Floaty / heavy fall inconsistency |
| 4 | Facing via slamming CFrame yaw every frame while Humanoid present | Twitchy orientation, fought AutoRotate remnants |

### Crabs (`src/server/EnemyFactory.lua`)

| # | Bug | Effect |
|---|-----|--------|
| 1 | `attachToRoot` WeldConstraint on hip + Motor6D limb chain | Welds competed with motors |
| 2 | Safety net only scanned `root:GetDescendants()` for constraints | Motor6Ds parented under legs/arms were missed → **SafetyWeld** glued animated parts to root → legs/claws frozen |
| 3 | Proportions / silhouette | Read as blob-with-sticks, not a stylized crab |

### Combat snappiness

| # | Bug | Effect |
|---|-----|--------|
| 1 | Swing VFX only after `CombatEvent` from server | Input → remote RTT delay before any slash feel |

---

## Fixes applied

### Movement — premium 2.5D

- **Stopped** rewriting full `hrp.CFrame` every frame.
- **X drive:** `AssemblyLinearVelocity` X only; Y left to Roblox physics.
- **Soft Z lock:** `AlignPosition` (`ForceLimitMode.PerAxis`, force on Z only) targeting `LANE_Z`.
- **Facing:** `AlignOrientation` (OneAttachment) instead of CFrame stomps.
- **Removed** stacked custom gravity.
- **Kept:** coyote, jump buffer, variable jump cut, dodge i-frames + trail, hangover/speed hooks.
- Camera spring unchanged; movement no longer fights it via CFrame thrash.

### Network ownership (`src/server/GameService.lua`)

- On `CharacterAdded`: `hrp:SetNetworkOwner(player)` before and after teleport / settle so client velocity sticks.

### Crabs — Motor6D assembly

- Animated chain uses **Motor6D only** (`RootHipMotor` → `HipMotor` → `KneeMotor` → `FootMotor`; `ClawMotor` → `PinchMotor`).
- Static shell / eyes still WeldConstraint to root.
- Pincer tips WeldConstraint to **claw** (not root).
- Safety net now uses model-wide `isMotorConnected` — **never** SafetyWelds Motor6D-driven parts.
- Better shell bevel stack, wider body, tripod gait phase, claw raise+snap on attack telegraph (pulsed during telegraph in `EnemyService`).

### Combat — local swing

- `VFX.SwingSlash` + immediate call from `InputController` when firing `RequestAttack` (mouse/J/gamepad).
- Server `CombatEvent` attack echo no longer spawns a second slash (shake + facing lock only).

---

## Verification notes

- `rojo` not installed on the box — build skipped per instructions.
- Push target: `origin/main` as Hatsunama.

## Files touched

- `src/client/Controllers/MovementController.lua` (rewrite)
- `src/server/GameService.lua` (network ownership)
- `src/server/EnemyFactory.lua` (crab + safety net + anim)
- `src/server/EnemyService.lua` (telegraph anim pulse)
- `src/client/Controllers/VFX.lua` (SwingSlash)
- `src/client/Controllers/InputController.lua` (local swing)
- `src/client/init.client.lua` (no double slash)
- `AUDIT.md` (this file)

---

# Full Quality Reconstruction — 2026-09-04 (ET)

**HEAD base:** `2c582a3` (P0 movement/crab fixes) — AlignPosition Z, AlignOrientation facing, no CFrame stomp, SetNetworkOwner **kept**.

## Player brief

Improve every aspect: story, levels, difficulty/power scaling, controls, enemy concepts, art top-to-bottom. Ship to `origin/main`.

## What changed

### Story
- New `Story.lua`: act Steve banter, hub headlines (updates after death), death lines, emotional+funny sunrise credits
- All 20 stage headlines rewritten to **advance plot** (not generic BREAKING)
- Acts 1–5 tone arc: comedy → unease → mutants → turtle rescue → facility reveal → Spillfather
- Newspaper cards show act name + storyBeat; Credits full-screen sunrise scroll

### Levels (`WorldBuilder` + `Stages` fields)
- Extended StageDef: `setPiece`, `hazards`, `lighting`, `storyBeat`, `scalingTier`, `goalLabel`, `steveAct`, `platformLedges`
- Unique set pieces per stage (pier, fryer, neon canopy, parking arena, canal pads, cypress, nests, gate, conveyor, pipe maze, barge gaps, helipad wind, boss arena)
- 3+ parallax layers with biome-specific silhouettes
- Hazards: oil/fryer slow, fire cones, HOA cones, red tide, wind push, jump pads
- Mini-arena spotlight framing for minibosses/boss
- Visible goals (pier light, nest, rig flare, etc.)
- Lighting profiles: dawnGold, neonGas, greenBlack, clinicalLab, industrialOrange, finaleRig, …
- Hub: real bonfire particles+flicker light, lawn chairs, cooler, news stand, pelican-shaped Steve

### Scaling (`Balance.lua`)
- HP `1+0.12*idx`, damage `1+0.08*idx`
- Max hostiles 2/3/4 by stage band
- Rarity +15/30/50% on attack **and** skill
- Hangover clears on Cold One; stage-1 only
- Wave spawner respects max-on-screen cap

### Controls
- AlignPosition Z MaxAxesForce raised (250k); snappier accel
- Longer dodge trail (6 ghosts), shorter dodge CD (0.72)
- Attack buffer 100ms; Space ignored while UI panels open
- Camera depth 32, FOV 65; controls HUD fades at hub

### Enemies
- Rethemed names/flavors to Florida folklore headlines
- Telegraph colors + ground fire-cone zones
- Art upgrades: crab sand material, Influencer selfie stick, HOA binder, hazmat grunt tanks, Spillfather sludge-mech chassis/tie/claws/oil drips

### Art / UI
- HUD: act banner, Florida Dew green HP, rarity-colored persona frames
- Newspaper: serif + red BREAKING badge
- Draft: thicker Unique/Legendary borders
- Credits: sunrise gradient + story lines

## Files touched (major)

- `src/shared/Balance.lua` (new), `Story.lua` (new), `Stages.lua`, `Enemies.lua`, `Constants.lua`
- `src/server/WorldBuilder.lua`, `GameService.lua`, `EnemyService.lua`, `EnemyFactory.lua`
- `src/client/Controllers/MovementController.lua`, `CameraController.lua`, `InputController.lua`
- `src/client/UI/HUD.lua`, `Newspaper.lua`, `Credits.lua`, `ItemDraft.lua`, `CaptainSteveUI.lua`
- `README.md`, `AUDIT.md`

## Verification

- `rojo` may be missing on box — build skipped if absent
- Push: `origin/main` as Hatsunama


---

# Playability P0 — 2026-09-04 (ET)

**Trigger:** Player feedback — moonwalk, unclickable "touch" prompts, spawn out of interact range, unplayable feel.

## Findings (root causes)

| # | Bug | Effect |
|---|-----|--------|
| 1 | `FACE_RIGHT = Angles(0,+90°,0)` → LookVector **−X** while D moves **+X** | Character literally runs backwards / moonwalks |
| 2 | Bonfire label `TOUCH TO BEGIN` + story "Touch the fire" but interact was **E-only** (no ClickDetector / ProximityPrompt) | Players click the flame; nothing happens |
| 3 | `SPAWN_X=8`, Flame at **x=20**, E range **10** → distance **12 > 10** | Fresh spawn: E does nothing until you walk closer — feels broken |
| 4 | Cold One pickup lived inside `DoAttack` | Had to attack near the can; walk-over did nothing |
| 5 | Captain Steve panel gated on toast containing `"Smash spare"` (never sent) | Talk did not open upgrades UI |
| 6 | Draft/Newspaper/Steve buttons lacked explicit Active/Selectable/ZIndex hardening | Risk of "can't click" on overlay UIs |

## Fixes

### Facing (`MovementController.lua`)
- **Before:** `AlignOrientation.CFrame = FACE_RIGHT/LEFT` via `CFrame.Angles(0, ±90°, 0)` (inverted vs +X travel); `RigidityEnabled=false`, Responsiveness 28
- **After:** `CFrame.lookAlong(Vector3.zero, Vector3.new(faceDir, 0, 0))` with `faceDir = sign(moveX)` so LookVector.X and velX share sign; `RigidityEnabled=true`; `hum:Move` world ±X so default Animate is not reverse relative to LookVector
- Kept AlignPosition Z lock + WalkSpeed=0 custom mover + network ownership from prior P0

### Interact / spawn
- `SPAWN_X` **8 → 18** (within 12 studs of Flame at x=20)
- `ProximityPrompt` on Flame + CaptainSteve: ActionText Start Run / Talk, ObjectText Bonfire / Captain Steve, Key=E, HoldDuration=0, **ClickablePrompt=true**, RequiresLineOfSight=false, MaxActivationDistance=12
- Server `ProximityPromptService.PromptTriggered` → `StartRun` / `talkCaptainSteve` (E remote path kept)
- Labels/HUD/Story/Stages/toasts: no more "TOUCH" — accurate "Press E · Start Run" / click prompt copy
- Cold One: **walkover** pickup in tick loop + clear label
- Steve UI opens on prompt/E interact only (not stage taglines)
- `StartRun` requires hub + re-entry claim to ignore double E/prompt

### UI click paths
- ItemDraft / Newspaper / CaptainSteveUI: Active/Selectable/ZIndex on TextButtons; dim frames `Active=false`

## Files touched
- `src/client/Controllers/MovementController.lua`
- `src/client/Controllers/InputController.lua`
- `src/client/init.client.lua`
- `src/client/UI/HUD.lua`, `ItemDraft.lua`, `Newspaper.lua`, `CaptainSteveUI.lua`
- `src/server/WorldBuilder.lua`, `GameService.lua`
- `src/shared/Constants.lua`, `Story.lua`, `Stages.lua`
- `AUDIT.md`

## Verification
- Facing math: identity LookVector (0,0,−1); old +90° Y → (−1,0,0); lookAlong(+X) → (+1,0,0) matches D/+velX
- Spawn distance to flame: |18−20|=2 < 12 prompt range
- Push: `origin/main`


---

# Full Quality Rebuild — 2026-09-04 (ET)

**HEAD base:** `c1dabf7` (playability P0) — movement/hub invariants **kept**.
**Trigger:** Player feedback — "not even close to good enough." Feel-first rebuild, no time limit.

## Invariants preserved (regression = failure)

- Movement: `CFrame.lookAlong` facing; AlignOrientation `RigidityEnabled=true`; AlignPosition Z-only; WalkSpeed=0; SetNetworkOwner
- Hub: `SPAWN_X=18` near Flame; ProximityPrompt `ClickablePrompt=true` on Flame + Steve; no fake TOUCH
- Cold One walkover; Community Standards (Florida Dew, no drugs, turtles allies)

## What actually changed in feel (first 60 seconds)

1. **Hitstop on every connect** (0.045s / 0.06s heavy) freezes player briefly — attacks *thunk*
2. **Enemy flinch + knockback + hit sparks** on every hit; empty swings no longer shake the camera
3. **Attack input buffer** (~120ms) queues swings through recovery instead of eating inputs
4. **Swap** is a real combo piece: burst VFX + brief i-frame + heavy knockback; tempo shift toast
5. **Skills** fire distinct patterns (beam / wave / aoe / dash / shield) not just damage numbers
6. **Rarity** now cuts skill cooldown (−8/−14/−20%) as well as boosting power

## Content / systems

### Story (`Story.lua`)
- Campaign bible: act tones, more Steve lines, rotating hub headlines after death, character sendoff credits, act openers on stage entry

### Levels (`WorldBuilder`)
- Segmented ground with biome materials + height variation
- Mid/late gaps (jump matters) + safety floor
- Mid-stage room gates: clear pocket → MidGate unlocks
- Set pieces / parallax / lighting kept and wired to gates

### Scaling (`Balance.lua`)
- HP/dmg curve softened (0.10 / 0.075) — elites via phases/hazards, not sponges
- Documented stage bands in comments
- `WaveSpawnCap` + rarity skill CDR

### Enemies
- Unique telegraphs: crab pinch combo, influencer flash cone, Karen aura+swipe, fire ground cone, drone mark circle, burrow ring, Spillfather 3-phase patterns
- Boss phase attrs at 66%/33% HP
- Silhouette upgrades: drone rotors, pelican beak, cart wheels, barrel stripes, Karen bob+citation
- Boss/elite base HP tuned down

### Presentation
- HUD controls accurate (click/E prompt, swap attack called out)
- Newspaper/Credits/Draft paths unchanged but fed richer Story copy

## Files touched (major)

- `src/shared/Constants.lua`, `Balance.lua`, `Story.lua`, `Enemies.lua`, `Stages.lua`
- `src/server/EnemyService.lua`, `GameService.lua`, `WorldBuilder.lua`, `EnemyFactory.lua`
- `src/client/Controllers/VFX.lua`, `MovementController.lua`, `InputController.lua`, `CameraController.lua`
- `src/client/init.client.lua`, `src/client/UI/HUD.lua`
- `README.md`, `AUDIT.md`

## Verification

- Grep: no TOUCH lies
- Invariants listed above present
- Do **not** auto-launch Studio on user PC — push only; user opens via Rojo
