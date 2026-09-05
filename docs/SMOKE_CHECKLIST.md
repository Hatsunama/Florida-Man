# Studio smoke checklist (manual) — N0–N8

Agents do **not** open Studio. Run after `rojo serve` / place open. Prefer friends-only soft launch place for Meta/DataStore proof.

## Preflight

- [ ] `git pull` · HEAD includes N8 FunnelService
- [ ] `./scripts/check_invariants.sh` green
- [ ] Dialogue policy: no Steve beep / typewriter SFX; Tagline/Toast/Newspaper only
- [ ] Art: InEngine_v3 Part kits (Mesh_v1 optional — skip if no uploads)

## Hub & FTUE (~60s)

1. [ ] Play at hub. Character faces move direction (A/D). No moonwalk.
2. [ ] Spawn near bonfire; ProximityPrompt **Start Run** visible; E or click works.
3. [ ] Captain Steve prompt opens upgrade / talk UI (popup text).
4. [ ] Loading splash shows Florida Man + Florida Dew / soft-launch tip.
5. [ ] Output: `[FM_FUNNEL] session_join` then after Start Run `hub_start`.

## Stage 1–3 playability

6. [ ] Start run → Daytona. Attack crab (J/LMB). Combat SFX if SoundIds loaded.
7. [ ] Dodge (Shift): i-frames vs telegraph.
8. [ ] Walk into Cold One (Florida Dew) — heal + hangover clear; Output `cold_one` (+ `ftue_60s`).
9. [ ] Clear / progress stages 1→2→3; on Gas Station clear Output `stage3_clear`.
10. [ ] Newspaper → draft (or skip if slots full); Output `draft_open` / `draft_pick`.
11. [ ] Death returns to hub; Output `death`; +1 item slot after first death.

## Combat / a11y (N4–N6)

12. [ ] Options: Mute SFX → combat silent; Tagline still readable; TextSpeed instant skips typewriter.
13. [ ] Reduce motion softens hitstop / shake / VFX.
14. [ ] Rejoin restores settings (DataStore or memory).
15. [ ] Lawn Dart arcs vs Roman Candle flat; foam vs fire; net roots briefly.
16. [ ] No ghost swings during server recovery (`attackReadyAt`).

## Level verbs (N5)

17. [ ] Act2 water timeout / pads feel different from Act1 hangover rhythm.
18. [ ] Turtle escort without attack-rescue.
19. [ ] MidGate lock Tagline once per act; empty waves never softlock.

## Soft launch / Meta (N8)

20. [ ] API Services enabled; Meta sunburn/deaths/`bestStageIndex` survive rejoin on published place.
21. [ ] Credits dismiss on tap/click; soft-launch policy lines present.
22. [ ] Touch: ATK/SKILL/DASH/USE visible when TouchEnabled.
23. [ ] External / friend clears stages 1–3 in ≤15 min uncoached (acceptance).

## Deferred to user (do not block code soft-launch)

- [ ] Mesh import → `Assets.Meshes` → runtime `ArtKit=Mesh_v1`
- [ ] AnimationIds pasted into `ArtAssets` (real uploads only)
- [ ] Marketplace 512 / 1920 thumbnails uploaded
- [ ] Remotes Studio hygiene (delete leftover `RequestJump` instance if old place file has it)
- [ ] Live Analytics custom-event charts for funnel names
