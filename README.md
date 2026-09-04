# Florida Man

**Tagline:** *It IS Florida… Anything is possible in the swamp I guess.*

A playable Roblox **2.5D side-scroll roguelite** inspired by *Skul: The Hero Slayer* — absurdist Florida Man headlines that become a real campaign, dual personas, weapon loadouts, item drafts, and a fight against **GulfGulp Energy** to save the turtles.

You wake after the last honest night of your life. Crabs stole your **Cold One** (**Florida Dew** — a heal/buff can, *not* alcohol). That's the joke. The truth: GulfGulp has been running "wildlife enhancement" in the swamp — radio-collared gators, fire lizards, oiled turtle nests so pipelines can claim "no habitat." **Captain Steve** (pelican) knows. He won't spell it out until the swamp.

## Story arc (5 acts · 20 stages + hub)

| Act | Stages | Tone |
|-----|--------|------|
| **1 Hangover Coast** | 1–5 | Viral comedy → first radio collar on Drive-Thru Gator |
| **2 The Swamp That Isn't Wild** | 6–10 | Snakes → mutants; Steve's tagline once; animals aren't the enemy |
| **3 Red Tide Bargain** | 11–12 | Rescue turtles; "cleanup" is a cover; Turtle Paladin |
| **4 Inside GulfGulp** | 13–19 | Gate → lab files → pipes → docks → barge → platform → helipad |
| **5 The Spillfather** | 20 | Oil-exec sludge mech (3 phases); save remaining turtles; sunrise credits |

Newspaper cards **advance the plot**. Hub headline board rotates after deaths. Unique Steve banter per act. Credits include character sendoffs.

## Requirements

- Roblox Studio
- Rojo 7.7+ (`rojo --version`)
- Rokit optional (`rokit.toml` pins Rojo)
- Git

## Open in Studio (Rojo)

1. Open repo folder (local clone path below after pull)
2. Run `rojo serve` at the repo root
3. In Roblox Studio, connect the **Rojo plugin** to `localhost:34872`
4. Press Play. Press **E** at the **bonfire** (or click the prompt) to start

```powershell
rojo build -o FloridaMan.rbxlx
```

## Controls

| Action | Keyboard | Xbox |
|--------|----------|------|
| Move (lane) | A/D or ←/→ | Left stick |
| Jump (coyote + variable) | Space | A |
| Attack (3-hit combo, ~120ms buffer) | Click / J | X / RT |
| Skill (pattern differs per persona) | K | Y / LT |
| Swap persona (+ swap attack, brief i-frame) | Q | B |
| Dodge dash (i-frames + trail) | Left Shift | RB |
| Interact (bonfire / Captain Steve) | E or click prompt | LB |

Movement is a **custom client 2.5D controller**: `AlignPosition` Z-lane lock, `AlignOrientation` via `CFrame.lookAlong` (+X when moving D), X via `AssemblyLinearVelocity` only (no CFrame stomp). Always-run with snappy accel.

**Combat feel:** hitstop (0.03–0.06s) + flinch/knockback + hit sparks on every connect; screen shake **only on hits**; empty swings stay quiet.

Camera: depth ~32 (Constants.CAMERA_DEPTH), FOV 65, shake on hits only.

## Difficulty + power scaling

Implemented in `Balance.lua` + `GameService` / `EnemyService` (curve documented in comments):

- **Enemy HP** `*= (1 + 0.10 * stageIndex)` · **damage** `*= (1 + 0.075 * stageIndex)`
- Stages 1–2 teach dodge/attack (≤2 on screen); 3–5 comedy roles; 6–10 mixes; 11–12 turtle pressure; 13–20 elites + hazards (not HP sponges)
- **Max hostiles on screen:** 2 → 3 → 4 (never cube soup)
- Persona rarity: **+15% / +30% / +50%** attack & skill power; skill CD **−8% / −14% / −20%**
- Hangover **only stage 1**, clears when you reclaim The Cold One
- Bosses use **phase pattern changes** (Spillfather slam → summon → arena slick)

## Level quality

Each stage has a unique **set piece**, **segmented ground** with biome materials/heights, mid/late **gaps** that make jump matter, mid-stage **room gates** (clear pocket → door opens), 3-layer parallax, cartoon hazards with telegraphs, visible goal lights, and biome lighting (Atmosphere + ColorCorrection + Bloom).

## Content counts

| Catalog | Count |
|---------|------:|
| Playable stages | **20** |
| Personas (dual kit) | **8** |
| Power-ups / items | **28** |
| Weapons | **28** |
| Enemies (unique behaviors) | **34** |

### Personas

Beach Burnout, Crab King, Gator Hauler, Snake Charmer, Golf Cart Bandit, Fireworks Enthusiast, Lizard Breath, Turtle Paladin.

### Enemy folklore (unique telegraphs)

Hangover Pinchers (pinch combo) · Influencer flash stun cone · HOA Karen slow aura + clipboard · Oil Gator sludge puddles · Fire Lizard ground fire cone · Mark Drone circle-then-dive · **The Spillfather** (3 phases). Turtles always allies.

## Layout

```
default.project.json
src/shared/   Personas Items Weapons Stages Enemies Balance Story Constants Remotes Util Types
src/server/   GameService WorldBuilder EnemyService EnemyFactory CombatService
src/client/   Controllers (Movement Camera Input VFX) UI (HUD Newspaper ItemDraft …)
```

## Content policy

- No drugs / intoxication gameplay
- No real alcohol — Cold One = Florida Dew heal can; hangover = slow status only
- Cartoon poof combat; no gore; turtles always allies
- Parody headlines only; no realistic firearms; no real names

## Lore

- Fire lizards + Lizard Breath persona
- Gators = GulfGulp science experiments (radio collars, sludge armor)
- Lab files: they engineered gators to guard spills
- Turtles always rescued
- Captain Steve: "It IS Florida… Anything is possible in the swamp I guess."
