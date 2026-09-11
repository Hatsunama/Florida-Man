> Historical planning/reference document. Current implementation and release decisions use [IMPLEMENTATION_PROGRESS](IMPLEMENTATION_PROGRESS.md) and [RELEASE_ACCEPTANCE](RELEASE_ACCEPTANCE.md). Claims below have not been re-certified for the repaired source.

# Playability Invariants (Phase 0 lock)

These must never regress. Smoke with `scripts/check_invariants.sh` + Studio checklist.

| Invariant | Expected |
|-----------|----------|
| Facing | `CFrame.lookAlong` with faceDir matching move/vel X sign |
| Lane lock | AlignPosition Z-only; WalkSpeed=0 custom mover |
| Network ownership | `SetNetworkOwner(player)` on character HRP |
| Hub spawn | `SPAWN_X = 18` near Flame (~x=20) |
| Bonfire / Steve | `ProximityPrompt` with `ClickablePrompt = true`, ActionText Press E / click |
| Cold One | Walkover pickup (not attack-gated) |
| Copy | No player-facing "TOUCH" lies for world interact |
| I-frames | **Server** `CombatService.HasIFrames` only — never trust client `IFrame` attr for damage |
| Attack facing | `CombatService.InLaneMelee` — facing-required except point-blank ≤2.5 |

## Phase 6 additions

| Invariant | Expected |
|-----------|----------|
| OilSlow | Hazard ticks set `OilSlow` via `HazardService` (not Hangover reuse) |
| MetaService | `DataStoreService` pcall + memory fallback; required by GameService |
| Daily luck | `Balance.DailyLuckBonus` exists; draft uses luck + daily |
| Telegraph pool | `FM_TelegraphPool` in EnemyService |

## N8 soft launch

| Invariant | Expected |
|-----------|----------|
| Dialogue | Tagline / Toast / Newspaper only — no dialogue VO / Steve beep / typewriter SFX |
| Audio policy | SFX combat only (+ optional UI click); ambience optional, never story |
| Florida Dew | Heal soda framing — not alcohol (maturity + Community Standards) |
| FunnelService | Server markers only; no client-trusted KPI grants; no telemetry secrets |
| Art soft launch | `InEngine_v3` Part kits OK; Mesh_v1 optional; no fake rbxassetid |
| Meta rejoin | DataStore v2 or memory fallback; cloud-offline toast once |
