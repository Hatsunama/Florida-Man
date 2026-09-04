# AUDIT — Phase 5 Full Campaign Polish + Audio

**Date:** 2026-09-04 (America/New_York)  
**Commit:** `4cb74ce`  
**Base HEAD before work:** `da76fdd`  
**Scope:** Audio director (SoundGroups + StageSounds + biome beds + UI stingers), Steve typewriter Tagline, campaign pacing (miniboss HP + rest toast + shop density doc), Credits sunrise polish, accessibility (ShakeEnabled + colorblind telegraph stripes), bug bash / softlock hunt. No Studio.

## Acceptance checklist

| Criterion | Result | Notes |
|-----------|:------:|-------|
| Core verbs never silent (SoundId non-empty) | **PASS** | `AudioCatalog.SFX` + WorldBuilder StageSounds; all IDs `rbxasset://…` |
| Shake toggle exists | **PASS** | Player attr `ShakeEnabled`; HUD “Shake: ON/OFF”; `CameraController.Shake` respects it |
| Invariants 8/8 | **PASS** | `./scripts/check_invariants.sh` all OK |
| Added steps before Phase 6 | **PASS** | See below |
| Honest about music quality | **PASS** | Biome beds = layered ambient SFX placeholders, not authored score |
| No Studio / rbxlx open | **PASS** | Agent did not launch Studio |

## Must-ship tasks

| # | Task | Result | Notes |
|---|------|:------:|-------|
| 1 | Audio director pass | **PASS** | `AudioDirector` SoundGroups Master/SFX/Music/UI/Ambience + ducking; StageSounds from catalog; biome looping beds; newspaper/draft/credits stingers |
| 2 | Steve lines typewriter | **PASS** | `Tagline.lua` typewriter + `SFX_Typewriter` / `SFX_SteveBeep`; VO skipped (no assets) |
| 3 | Campaign pacing | **PASS** | Act1–2 miniboss base HP↓ + `Balance.MinibossHpMult`; `Balance.RestToast` on act cross; shop = hub Steve only (documented) |
| 4 | Credits / sunrise | **PASS** | UIGradient sky + sun disk, ~28s scroll, `SFX_CreditsSwell` + duck |
| 5 | Accessibility | **PASS** | `Settings` module; HUD toggles; `ShakeEnabled`; telegraph `TelegraphStripe` + DiamondPlate when `ColorblindTelegraphs` |
| 6 | Bug bash | **PASS** | No `GetAttribute("IFrame")` damage trust leftovers; requires resolve; invariants green |
| 7 | Softlock hunt | **PASS** | MidGate unlock on locked+0 hostiles; turtle prompt re-attach + dist 12; soft-fall Y&lt;−2 → checkpoint |

## Audio mix

| Bus | Role |
|-----|------|
| FM_Master | Root volume |
| FM_SFX | Swing / hit / dodge / splash / flame / footstep |
| FM_Music | Credits swell (placeholder) |
| FM_UI | Newspaper / draft / typewriter / UI click |
| FM_Ambience | Biome looping beds |

**Music honesty:** No free Roblox music asset IDs were known-good for shipping. Biomes use **layered looping ambient SFX** (`impact_water`, `swoosh`, `electronicpingshort`, `collision`) at low volume/pitch so the world is never silent. Replace `AudioCatalog.BIOME_BEDS` SoundIds in Studio when licensed beds exist.

**Core verbs:** `SFX_Swing`, `SFX_Hit`, `SFX_Dodge`, `SFX_DraftSting`, `SFX_BossIntro`, `SFX_UIClick`, `SFX_Footstep`, `SFX_Splash`, `SFX_Flame` — all non-empty `rbxasset://`.

## Campaign pacing

| Change | Detail |
|--------|--------|
| CrabKingBoss | 95 → 85 HP |
| SlushieKing | 115 → 100 |
| HOAHydra | 145 → 125 |
| DriveThruGator | 130 → 115 |
| MinibossHpMult | Act1 ×0.88, Act2 ×0.92, else ×1.0 |
| Rest toast | On act change via `Balance.RestToast` |
| Shop density | **Captain Steve upgrades at hub only** — intentional; no mid-act shops |

## Softlock hunt

1. **MidGate:** while `midRoomState=="locked"` and `CountHostile()==0` → unlock + fanfare (never stick locked after clear).
2. **Turtle:** SpawnTurtle `MaxActivationDistance=12`; heartbeat re-creates missing `ProximityPrompt` on unrescued turtles.
3. **Soft-fall:** Y &lt; −2 respawns to `checkpointX` (barge gaps caught earlier); splash SFX + shake.

## IFrame trust

`grep GetAttribute("IFrame")` across `src/` → **no damage-trust leftovers**. Immunity remains `CombatService.HasIFrames` only (`IFrameVFX` is juice).

## Invariants (Phase 0 lock)

```
OK  lookAlong facing
OK  SPAWN_X = 18
OK  ClickablePrompt
OK  HasIFrames server
OK  CombatService require GS
OK  MobileControls
OK  SoundId smoke
OK  OilSlow
```

## Grades (post Phase 5)

| Area | Grade | Delta |
|------|:-----:|-------|
| Audio mix / verbs | **B** | Was D/C — buses + non-empty IDs + beds |
| Music / biome beds | **C+** | Honest placeholders; never silent |
| Steve vignettes | **B** | Typewriter + SFX (no VO) |
| Credits / sunrise | **B** | Gradient + slower scroll + swell |
| Accessibility | **B** | Shake + CB telegraph pattern |
| Softlocks | **B** | MidGate / turtle / soft-fall hardened |
| Campaign pacing | **B−** | Act1–2 miniboss softer; hub shop OK |

## Added steps before Phase 6

1. **P5.1 Studio smoke** — confirm each core SFX audible; biome beds loop; newspaper/draft/credits stingers; Shake OFF stops shake; CB Tele ON → DiamondPlate telegraphs.
2. **P5.2 Music swap** — upload licensed biome/boss loops; wire IDs into `AudioCatalog.BIOME_BEDS` / optional `MUSIC_*`; keep ambient layers as fallback.
3. **P5.3 Ducking tune** — measure Music/Ambience duck during UI; avoid pumping on typewriter ticks.
4. **P5.4 Settings persist** — Phase 6 DataStore should save `ShakeEnabled` / `ColorblindTelegraphs`.
5. **P5.5 Steve VO optional** — if short VO uploaded, play beside typewriter without blocking text.
6. **P5.6 Full-run softlock pass** — external tester ≤3 softlocks acceptance; MidGate wave fail cases; barge multi-gap.
7. **P6 gate:** meta/DataStore + publish pack may start after Studio confirms audio buses + a11y toggles.

## Gate to Phase 6

Phase 5 acceptance met in-repo (no Studio). Phase 6 may begin for DataStore meta / publish checklist; do not claim commercial music quality until beds are replaced.

## Shop density (design note)

Captain Steve (upgrades / smash / talk) remains **hub-only**. Mid-stage “shops” were not added — rest toast tells players to return to hub. This is accepted density for Phase 5.
