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
