# Florida Man — Full-System Audit (Ruthless)

**Date:** 2026-09-04 (America/New_York)  
**HEAD audited:** `8e260c8ebb8adff1b22251faffc0c7098de5c14f`  
**Scope:** Every subsystem — art, movement, UX, combat, AI, world, story, balance, audio, architecture  
**Method:** Static evidence from source (paths + line-level issues). No Studio playtest in this pass.  
**Companion plan:** [`docs/PLAN_100X.md`](PLAN_100X.md)

---

## Executive scorecard

| Area | Grade | One-line verdict |
|------|:-----:|------------------|
| A. Art / visuals | **D** | Procedural Part silhouettes + neon VFX; zero MeshPart/SurfaceAppearance/custom character pipeline |
| B. Movement & camera | **B−** | Facing/lane P0 fixed; still default R15 Animate + residual jitter risks |
| C. Interactions & UX | **C+** | Prompts/spawn fixed; first-60s onboarding is toast spam; mobile touch combat absent |
| D. Combat systems | **D+** | Hitstop exists; combat unowned/fragmented; 28 weapons are stat sheets; CombatService dead |
| E. Enemies & AI | **C** | Telegraph skins on chase AI; boss “phases” = HP thresholds |
| F. Levels / world | **C−** | Unique décor on one lane slab; gaps neutered by SafetyFloor |
| G. Story & writing | **B−** | Strong bible + headlines; delivery is cards/toasts, not scenes |
| H. Progression / balance | **C** | Curve OK on paper; many item specials / weapon kinds unimplemented |
| I. Audio | **F** | Empty `Sound` stubs; no music; no mix bus |
| J. Architecture & production | **D** | 1255-line GameService god-object; no tests/CI/DataStore/publish assets |

**Overall product feel:** Playable prototype with a sharp comedy voice — **not** commercial Roblox indie yet. Recent P0s (facing, prompts, spawn) stopped the “unplayable” floor; they did not buy art, audio, combat ownership, or production rigor.

---

## What “cheap” means here (player-felt)

1. **Silent world** — swings fire, crabs pinch, Spillfather slams: no hit SFX, no music sting. Brain reads “placeholder.”
2. **Lego silhouettes** — every enemy/prop is SmoothPlastic Parts. Players compare to MeshPart experiences on the same platform.
3. **Same fight, different sticker** — unique telegraph *colors* over the same “walk at player → zone → damage” loop.
4. **Catalog theater** — 28 weapons / 28 items / 34 enemies advertised; weapons don’t change attack *behavior*; several item `special`s never run.
5. **God-object fragility** — one 1255-line service owns run loop, combat, hazards, meta, remotes → regressions inevitable without tests.

---

## A. Art / “sprites” / visuals — Grade: **D**

### Current state
- **EnemyFactory** (`src/server/EnemyFactory.lua`, ~997 lines): builds welded/Motor6D Part silhouettes per `shape` (crab, gator, humanoid, slime, drone, pelican, cart, barrel, turtle, boss). Crab Motor6D gait + claw snap is the best piece.
- **WorldBuilder** (`src/server/WorldBuilder.lua`, ~939 lines): biome materials, 3 parallax layers (`_Parallax`), lighting profiles (`LIGHTING_PROFILES` ~L83–97), set-piece décor (`_SetPiece` ~L320–535), hub bonfire particles.
- **VFX** (`src/client/Controllers/VFX.lua`): neon Part slashes, ParticleEmitter sparks, skill pattern Parts (beam/wave/aoe/dash/shield).
- **UI** (`src/client/UI/*`): pure TextLabel/TextButton/Frame + UIStroke/UICorner. Newspaper uses `Enum.Font.Antique`. HUD Florida-Dew green HP (`HUD.lua` ~L75).

### What’s broken / weak
- **Zero MeshParts, SurfaceAppearance, TextureIDs, or imported FBX** anywhere in `src/` (grep clean).
- **Player is stock R15** with default Animate; personas change numbers/colors in HUD frames, not body.
- **No AnimationController / custom Animation tracks** for player attacks, swaps, skills, or enemy attacks (EnemyFactory Motor6D procedural only).
- **Weapon `vfx` strings** in `Weapons.lua` (punch/slap/dart/…) are never consumed by VFX or GameService.
- **No experience thumbnail, icon, loading screen, or marketplace art** in repo.
- **Steve / crabs / Spillfather** remain stacked primitives — readable folklore *ideas*, not shippable characters.

### Why it feels cheap
Roblox commercial bar in 2026 is MeshPart + SurfaceAppearance + authored anims + UI images. This reads as “Studio Parts demo with great writing.”

### Evidence
- `EnemyFactory.lua` L21–42 `part()` → always `Instance.new("Part")`
- `WorldBuilder.lua` L18–38 same Part factory for world
- `VFX.lua` L45–84 swing = neon Part tween
- No `ImageLabel` art assets in UI modules

---

## B. Movement & camera — Grade: **B−**

### Current state
- **MovementController** (`src/client/Controllers/MovementController.lua`, 415 lines): X via `AssemblyLinearVelocity` only; Z via `AlignPosition` PerAxis (MaxAxesForce Z=250000); facing via `AlignOrientation` + `CFrame.lookAlong` (moonwalk fix); coyote 0.12 / jump buffer 0.12 / variable cut; dodge dash + ghost trail + client IFrame attr.
- **Network ownership** asserted in `GameService.InitPlayer` (`GameService.lua` ~L916–934).
- **CameraController** (104 lines): spring follow, deadzone, FOV 65, depth from `Constants.CAMERA_DEPTH=32`, shake on combat events.

### What’s broken / weak
- **No custom locomotion/combat animations** — `hum:Move(±X)` drives default Animate only (`MovementController.lua` L403–408). Attack facing lock fights run cycle visually.
- **Hitstop zeros `velX`** (L308–319) — can feel sticky if server hitspam / multi-hit skills stack hitstops.
- **Server soft Z correction** still stomps CFrame if `|Z| > 2.5` (`GameService.lua` L1237–1239) — can fight client AlignPosition under lag.
- **Gamepad stick polled via `GetGamepadState` every RenderStepped** (L336–342) — brittle vs InputChanged; touch sticks nonexistent.
- **LandSquash attribute** set but no visual squash on character (camera bump only).

### Remaining moonwalk / jitter risks
| Risk | Source | Impact |
|------|--------|--------|
| LookVector vs MoveDirection desync after attack lock | LockFacing + AlignOrientation | Brief slide-facing mismatch |
| Server Z CFrame stomp | GameService tick | Micro-teleport on desync |
| Dodge i-frame client-set before server ack | MovementController L236 | Rare desync if remote delayed |
| Double ownership / teleport races | CharacterAdded wait 0.3 + teleports | Occasional rubber-band on stage load |

### Why it feels cheap
Movement *math* is competent; the **body** still looks like a default avatar moonwalking through a Parts diorama. Feel without animation reads unfinished.

---

## C. Interactions & UX — Grade: **C+**

### Current state
- Hub **ProximityPrompt** on Flame + CaptainSteve: `ClickablePrompt=true`, MaxDistance 12 (`WorldBuilder.lua` L59–71, L606–611, L682–687).
- `SPAWN_X = 18` near Flame at x≈20 (`Constants.lua` L31).
- Cold One **walkover** (`GameService.tryColdOnePickup` ~L975–995), not attack-gated.
- Draft / Newspaper / Steve buttons hardened Active/Selectable (prior P0).
- Gamepad: ContextActionService binds for attack/skill/swap/dodge/interact (`InputController.lua` L119–152).

### What’s broken / weak
- **No mobile on-screen combat buttons** — touch players get default jump only; attack requires mouse semantics that mobile lacks.
- **Weapon keys 1/2/3 are empty stubs** (`InputController.lua` L114–116).
- **First 60 seconds:** toast loop every 4s reminding E on bonfire (`init.client.lua` L192–208) — not a tutorial beat map (move → attack → dodge → Cold One → swap).
- **Turtle rescue via attacking near ally** inside `DoAttack` — discoverability poor.
- **Captain Steve UI** only after prompt; upgrade economy (Sunburn) weakly explained in-panel.
- **Hazard oil slow reuses `Hangover` attribute** (`GameService.lua` L1208) — HUD may lie about hangover after stage 1.

### Lying prompts / dead clicks (post-P0 status)
- Prior TOUCH lies: **fixed** (grep clean of player-facing TOUCH).
- Remaining soft lies: weapon cycle keys advertised nowhere but stubbed; `PlaySound` fires names with empty SoundIds (silent “success”).
- MidGate can unlock while player is elsewhere (`TickWaves` L878–887) — door opens with a toast, no camera beat.

### Why it feels cheap
Controls work for keyboard veterans; a new Roblox player on phone experiences a mute mannequin next to a fire.

---

## D. Combat systems — Grade: **D+**

### Current state
- **Feel claims (partially real):** hitstop 0.045/0.06 (`Constants.lua` L16–17), flinch attr (`EnemyService.ApplyDamage` L104–105), knockback PivotTo (L121–131), local swing VFX on input (`InputController.doSwingFire`), shake only on `hitConnect` (`init.client.lua` L120–127).
- **Skills:** `skillKind` branches in `DoSkill` (shield/beam/wave/aoe/summon/dash) — different ranges, shared “apply damage in shape” DNA (`GameService.lua` L702–748).
- **Swap attack:** damage + brief IFrame + VFX (`DoSwap` L788–836).
- **Attack buffer:** client-only ~120ms (`InputController.lua` L69–83).

### CombatService.lua is ~22 lines — fragmented / unowned?
**Yes.** `CombatService.lua` exposes `LaneKnockback` + `InLaneMelee` and is **never `require`d** by GameService or EnemyService (grep: definition only). Real combat lives in:
- `GameService.DoAttack` / `DoSkill` / `DoSwap` / `DoDodge`
- `EnemyService.ApplyDamage` / `_TelegraphAttack`
- Client VFX + hitstop

There is **no combat owner module**, no hitbox service, no weapon behavior table, no regression harness.

### Weapons vs personas muddiness
- Personas own attackDamage, attackSpeed (speed unused in DoAttack recovery), skill kit.
- Weapons add `(weapon.damage - 10) * 0.65` and range/knockback (`DoAttack` L631–640).
- **`weapon.kind` (melee/ranged/thrown) never branches** — Lawn Dart / Roman Candle still melee lane traces.
- **`weapon.vfx` unused** — Flip-Flop and Bare Hands look identical (same neon slash).
- Player fantasy: “loadout mastery.” Reality: two overlapping damage scalars.

### Hitstop / flinch / knockback — reality vs claim
| Claim | Reality |
|-------|---------|
| Hitstop every connect | True for damage applies → `hitConnect` remote → client Hitstop |
| Enemy flinch readable | True briefly; AI skips while `FlinchUntil` |
| Knockback | True but **PivotTo teleport**, not physics impulse — can look snapped |
| Empty swing quiet | True (no shake); still silent audio |

### Server authority / exploit surface / latency
- `RequestAttack` / `RequestSkill` / `RequestDodge` / `RequestSwap`: minimal validation; client can spam remotes (server skill CD / dodge CD exist; **attack has no server recovery gate** beyond combo window bookkeeping).
- **Client sets `IFrame` attribute** on dodge/swap before/along server (`MovementController` L236; server also sets). Attribute is not a secure channel — exploiters can set IFrame locally; **server checks `char:GetAttribute("IFrame")`** in `ApplyDamageToPlayer` (L583) — **trusts client attribute** → godmode surface.
- Enemy damage path uses PendingDamage attributes (`EnemyService` L531–532) — another attribute bridge.
- Feel latency: swing VFX instant (good); confirm hit still RTT-bound (acceptable if juice covers it).

### Operator / logic landmine
`DoAttack` hit test (`GameService.lua` L658):
```lua
if math.abs(dx) <= range and math.sign(dx + 0.001) == s.facing or math.abs(dx) < 4 then
```
Lua precedence makes this `(A and B) or C` — **rear hits within 4 studs always connect**, undermining facing discipline.

### Why it feels cheap
Juice macros without a combat *design system*. Catalog size without behavioral differentiation = spreadsheet game.

---

## E. Enemies & AI — Grade: **C**

### Current state
- 34 defs in `Enemies.lua` with folklore names, telegraph colors, behaviors: scuttle/charger/burrower/hopper/spitter/puddle/firearc/summoner/tank/chase.
- `EnemyService._TelegraphAttack` (~L379–535): role-specific zone layouts (fire cone, Karen aura, drone mark, crab pinch double-zone, Spillfather phase zones).
- Density caps via `Balance.MaxHostiles` / `WaveSpawnCap`.

### What’s broken / weak
- **Locomotion is still lane chase** with PivotTo (`EnemyService.StartAI` L293–357). “Unique AI” is mostly unique **wind-up décor**.
- **Boss phases:** `BossPhase` flips at 66%/33% HP (`ApplyDamage` L135–148). Phase 2–3 = faster tele + wider zones + summons/puddles — **not** new move lists, arenascripts, or invuln transitions with choreography.
- **Minibosses** share same phase attr path; Slushie King / HOA Hydra don’t get bespoke phase graphs.
- **Readability:** neon telegraph Parts help; overlapping MaxHostiles=4 + puddles + MidGate can smear late stages.
- **Ally turtles** idle-bob only; rescue is proximity-in-attack, not a dedicated interact.

### Why it feels cheap
Headline names slap; after three fights the body learns “wait for red rectangle, dodge, mash.”

---

## F. Levels / World — Grade: **C−**

### Current state
- 20 stages + hub in `Stages.lua` with `setPiece`, `hazards`, `lighting`, `storyBeat`, `platformLedges`.
- WorldBuilder: segmented ground, mid/late gaps, MidGate (`_MidRoomGate` L784+), platforms, set pieces (pier, fryer, neon canopy, parking arena, canal pads, cypress, nests, gate, conveyor, pipes, barge, helipad, Spillfather arena).
- Lighting: Atmosphere + ColorCorrection + Bloom + DoF per profile.

### What’s broken / weak
- **Set pieces are thin décor on one Z-lane slab** — few force new verbs beyond “walk right, jump gap, clear MidGate.”
- **SafetyFloor at Y=-8** (`WorldBuilder.lua` L772–781) + jump pads → falling has no stakes; gaps are visual.
- **Hazards:** oil slow mutates Hangover flag; `hoaCone` is mostly a labeled prop; canalWater JumpPad path commented as visual-only for hazard branch (actual JumpPad via separate attr works).
- **Replay structure:** single linear campaign; death → hub → restart stage 1. No alt routes, no stage select, no daily seed.
- **World rebuild clears GameWorld each stage** — fine for prototype; no streaming, no persistent hub instance separation beyond rebuild.

### Why it feels cheap
Biomes change fog tint; the *verb loop* does not. Players feel a hallway with stickers.

---

## G. Story & writing — Grade: **B−**

### Current state
- `Story.lua` (144 lines): 5 acts with Steve lines, hub headlines after death, death lines, credits sendoffs, act openers.
- Stage headlines in `Stages.lua` advance GulfGulp / collar / turtle plot (not generic BREAKING spam).
- Newspaper UI shows act + storyBeat; Credits sunrise scroll.

### What’s broken / weak
- **No staged scenes** — emotional beats = toast + newspaper card + tagline overlay.
- **Character arcs** exist as credits jokes; in-run Steve doesn’t react to turtle count / boss phase.
- **Tone** is consistently Florida Man absurdist + soft eco-revenge — strongest asset in the repo.
- Community policy constraints (no alcohol/drugs) handled via Florida Dew framing — good.

### Why it still isn’t “A”
Writing is A-material trapped in C presentation. Without VO, comics panels, or staged beats, payoff under-delivers.

---

## H. Progression / balance — Grade: **C**

### Current state
- `Balance.lua`: HP `1+0.10*idx`, dmg `1+0.075*idx`, rarity power/CDR, max hostiles bands — well documented.
- Meta: deaths → item slots; sunburn currency; persona rarity upgrades at Steve; unlock personas via stage drops.
- Draft 3-pick after stages (`Items.RollDraft`).

### What’s broken / weak
- **Item specials largely dead:** `lifesteal` (HEROIC set), `paperCut`, `sunburnFind`, `aggro`, `radio` — not implemented in combat tick (only `antiCorp`, `badge`, `absorb`, `stageHeal` partially).
- **Inscription sets** apply HP/damage/luck in `computeStats`; HEROIC “heal on hit” text is a lie.
- **Weapon unlocks** thin; many catalog weapons never enter `unlockedWeapons`.
- **Power fantasy vs fairness:** dodge + IFrame + rarity CDR can trivialize; unlucky drafts still completable *if* player masters dodge — OK intent, poor teaching.
- **No persistent DataStore** — meta unlocks die with server session.

### Why it feels cheap
Draft UI promises builds; invisible specials mean builds are mostly +HP/+dmg stickers.

---

## I. Audio — Grade: **F**

### Current state
- `WorldBuilder` creates `StageSounds` folder with named `Sound` instances (`WorldBuilder.lua` L916–925) — **SoundId never set**.
- Client `PlaySound` remote plays only if `SoundId ~= ""` (`init.client.lua` L72–81) → **always no-ops**.
- `SoundService.RespectFilteringEnabled = true` in project JSON; no music, no SoundGroups, no ducking.

### What’s broken / weak
Everything. No hit, swing, UI, ambience, boss sting, or hub loop.

### Why it feels cheap
Silence is the fastest way to make competent VFX feel like a mute tech demo.

---

## J. Architecture & production — Grade: **D**

### Current state
- Rojo `default.project.json` maps shared/server/client; Rokit pins Rojo.
- Server: GameService (1255), WorldBuilder (939), EnemyFactory (997), EnemyService (537), CombatService (22 orphan), init.
- Client: controllers + UI modules; clean-ish separation vs server.

### What’s broken / weak
| Issue | Evidence |
|-------|----------|
| God-object | `GameService.lua` 1255 lines: hub, stages, combat, drafts, hazards, remotes, meta |
| Dead module | `CombatService` unused |
| No tests | No `tests/`, no Spec, no CI workflows |
| No CI | No `.github/` |
| No persistence | No DataStore/ProfileService |
| Types hollow | `Types.lua` is 4 lines |
| Publish gap | No thumbnails, no maturity questionnaire notes, no performance budgets, no StreamingEnabled strategy |
| Content pipeline | All content is Lua tables + runtime Parts — no Blender/RBXM art pipeline |

### Roblox publish requirements (gap list)
- Experience icons/thumbnails/ads
- Age / maturity labels appropriate to cartoon combat + parody
- Performance: part-count budgets per stage (procedural enemies + telegraphs + particles can spike)
- Streaming / memory for longer sessions
- Privacy / remotes hardening (exploit surface above)
- Soft launch analytics (none)

### Why it feels cheap
Even if art improved, one god-file + no tests means every “feel fix” re-breaks facing/prompts. Production risk is structural.

---

## Cross-cutting P0 defects still open (code)

1. **Silent audio stubs** — `WorldBuilder.lua` L919–924; `init.client.lua` L72–81  
2. **Client-trusted IFrame attribute** — godmode surface (`GameService.ApplyDamageToPlayer` L583)  
3. **DoAttack facing OR-bypass** — `GameService.lua` L658  
4. **CombatService orphan / combat unowned** — fragmentation  
5. **Weapons kind/vfx unused** — catalog fraud vs feel  
6. **Item specials / HEROIC lifesteal unimplemented**  
7. **No mobile attack UI**  
8. **No automated regression for facing/prompt/spawn**  
9. **SafetyFloor neuters platforming**  
10. **GameService god-object** blocks safe iteration  

---

## Honesty check vs README claims

| README claim | Audit verdict |
|--------------|---------------|
| Unique enemy behaviors (34) | **Telegraphs unique; locomotion shared** — oversell |
| Combat hitstop/flinch/swap mastery | **Macros exist; depth does not** |
| Unique set pieces / hazards | **Décor unique; verbs shared** |
| 28 weapons | **28 stat rows, ~1 attack shape** |
| Premium 2.5D mover | **Fair for code; unfair for animation presentation** |
| Story campaign | **Writing strong; staging weak** |

---

## Grade rationale summary

Ruthless curve: **B** means “shippable indie slice with gaps.” Nothing here is B except movement math (B−) and writing (B−). Art/audio/architecture/combat ownership drag the product to **prototype**.

**Next:** execute [`PLAN_100X.md`](PLAN_100X.md) in phase order — do not spray polish before Phase 0 lock.
