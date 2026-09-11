# Movement authority re-audit — 2026-09-05

Two static findings motivated this change: position-sensitive remote commands used client-owned character coordinates before the separate movement tick accepted them, and the former envelope permitted sustained 48-stud-per-second travel regardless of normal movement speed. The same old envelope could reject a legitimate 18-stud dodge over 0.18 seconds followed by ordinary movement within its 0.35-second aggregate window.

## Ownership and resulting behavior

- `src/server/MovementAuthority.lua` owns accepted coordinates and server-issued movement allowances. It depends on the pure envelope, constants, and Roblox services. It does not require combat, enemy, run-context, profile, or hazard services.
- `src/shared/MovementEnvelope.lua` accounts for elapsed normal movement once and preserves a finite four-stud replication credit across samples. Constant excess speed consumes that credit instead of receiving another four studs every frame.
- An accepted server dodge grants its excess distance above normal movement, with a short expiry. Legitimate fast builds use their published speed, rather than a fixed ceiling. Rejected or repeated checks do not replenish an expired dodge.
- The client implementation task changed both dodge displacement and animation to start on the server's accepted event. This removes the ordering race in which predicted physics could reach the server before the corresponding movement allowance.
- Hazard overlap issues bounded external horizontal movement and approved vertical impulses. Normal jumps and falls are checked against a gravity-based upper height envelope; server raycasts establish support. Pad impulses tolerate delayed departure from the ground.
- Normal teleports, skill dashes, and soft-fall recovery record the exact server destination immediately. Client-facing reset revisions no longer bypass the server movement check, and no future teleport window accepts an unrelated coordinate.
- `GameService` integrates synchronous `Validate(player)` calls before positional command dispatch. The validating function does not yield: an invalid coordinate is corrected before the command can commit damage or progression. The hazard tick uses the same boundary in the hub and active stages.

The movement service's public action grants are server-module methods, not remotes. The existing admitted-player, cooldown, phase, offered-reward, inventory, and profile controls remain necessary at their respective boundaries.

## Validation performed

The pinned Luau interpreter passed **1,165 assertions** in `tests/movement-envelope.test.luau` during the initial implementation pass. These execute the actual pure acceptance policy. Covered cases include sustained normal/slow/fast movement; normal movement following a full 18/0.18 dodge; expired and permanently extended dodges; authorized and expired horizontal hazard forces; same-frame rejected commands; exact teleport baselines; invalid altitude/lane/non-finite coordinates; ordinary jump and landing; a delayed 62-stud-per-second pad impulse; falling from a platform; and stationary airborne cheating.

No engine, networking, collision, or successful gameplay was simulated by this test. The parent implementation task owns sequential compilation, Roblox type analysis, packaging, and any real Studio verification. Its final evidence supersedes this initial test count if the policy changes.

## Residual limits and follow-up

The envelope is a bounded plausibility check, not a full authoritative physics simulation. Its four-stud replication credit, three-stud vertical margin, and 0.22-second launch/dodge replication grace intentionally admit limited positional uncertainty. Platform edges, changing support, delayed replication, air jumps, repeated pads, fast builds, and mixed dodge/hazard movement still need real engine traces. Very high latency or hitches beyond the accepted windows can trigger correction and must not be claimed compatible without measurement.

Current hazard definitions supply downward vertical wind only (`velocityY = -4`), which cannot exceed the upward height bound. `SetExternal` does not add a positive vertical-force allowance. Adding an upward wind definition requires an explicit vertical budget and regression coverage; otherwise a long upward force could cause false corrections.

The asynchronous enemy telegraph hit check was identified as another live-coordinate consumer during the implementation re-audit. The parent task was notified to validate/correct movement immediately before that geometry check. It must evaluate the accepted/corrected root afterward; skipping damage on rejected movement would itself enable evasion. This integration was outside this worker's file ownership and must be verified in the final source.

Read-only audit observations identified no additional supported injection, credential, cross-user profile access, reward replay, purchase bypass, or provider-control issue in the fully reviewed command, combat, progression, persistence, telemetry, build, and QA boundaries. This statement is scoped to reviewed source and is not a guarantee about every repository artifact or the live deployment.

