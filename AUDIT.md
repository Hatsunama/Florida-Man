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
