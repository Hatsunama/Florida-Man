# Florida Man

**Tagline:** *It IS Florida… Anything is possible in the swamp I guess.*

A playable Roblox **2.5D side-scroll roguelite** inspired by *Skul: The Hero Slayer* — absurdist Florida Man headlines that become a real campaign, dual personas, weapon loadouts, item drafts, and a fight against **GulfGulp Energy** to save the turtles.

You wake after the last honest night of your life. Crabs stole your **Cold One** (**Florida Dew** — a heal/buff can, *not* alcohol). That's the joke. The truth: GulfGulp has been running "wildlife enhancement" in the swamp — radio-collared gators, fire lizards, oiled turtle nests so pipelines can claim "no habitat." **Captain Steve** (pelican) knows. He won't spell it out until the swamp.

## Story arc (5 acts · 20 stages + hub)

| Act | Stages | Tone |
|-----|--------|------|
| **1 Hangover Coast** | 1–5 | Viral comedy → first radio collar on Drive-Thru Gator |
| **2 The Swamp That Isn't Wild** | 6–10 | Snakes → mutants; Steve's tagline; animals aren't the enemy |
| **3 Red Tide Bargain** | 11–12 | Rescue turtles; "cleanup" is a cover; Turtle Paladin |
| **4 Inside GulfGulp** | 13–19 | Gate → lab files → pipes → docks → barge → platform → helipad |
| **5 The Spillfather** | 20 | Oil-exec sludge mech; save remaining turtles; sunrise credits |

Newspaper cards **advance the plot**. Hub headline board updates after first death. Unique Steve banter per act.

## Requirements

- Roblox Studio
- Rojo 7.7+ (`rojo --version`)
- Rokit optional (`rokit.toml` pins Rojo)
- Git

## Open in Studio (Rojo)

1. Open repo folder
2. Run `rojo serve` at the repo root
3. In Roblox Studio, connect the **Rojo plugin** to `localhost:34872`
4. Press Play. Touch the **bonfire** (or press **E**) to start

```powershell
rojo build -o FloridaMan.rbxlx
```

## Controls

| Action | Keyboard | Xbox |
|--------|----------|------|
| Move (lane) | A/D or ←/→ | Left stick |
| Jump (coyote + variable) | Space | A |
| Attack (3-hit combo, 100ms buffer) | Click / J | X / RT |
| Skill | K | Y / LT |
| Swap persona (+ swap attack) | Q | B |
| Dodge dash (i-frames + trail) | Left Shift | RB |
| Interact (bonfire / Captain Steve) | E | LB |

Movement is a **custom client 2.5D controller**: `AlignPosition` Z-lane lock, `AlignOrientation` facing, X via `AssemblyLinearVelocity` only (no CFrame stomp). Always-run with snappy accel. Controls prompt fades at hub.

Camera: depth ~32, FOV 65, shake on hits only.

## Difficulty + power scaling

Implemented in `Balance.lua` + `GameService` / `EnemyService`:

- **Enemy HP** `*= (1 + 0.12 * stageIndex)` · **damage** `*= (1 + 0.08 * stageIndex)`
- Stages 1–5 tutorial-fair (HP ~25–50 base, slow telegraphs, ≤2–3 on screen)
- 6–10 denser packs + elites; 11–15 mixed roles + turtle pressure; 16–20 elites + hazards + built-character bosses
- **Max hostiles on screen:** 2 → 3 → 4 (never cube soup)
- Persona rarity: **+15% / +30% / +50%** attack & skill power (Rare / Unique / Legendary)
- Hangover **only stage 1**, clears when you reclaim The Cold One
- Lucky draft melts late game; unlucky run stays completable with dodge skill

## Level quality

Each stage has a unique **set piece** (collapsing pier, fryer oil, neon canopy, canal jump pads, cypress canopy, lab conveyor, pipe maze, barge gaps, helipad wind, Spillfather arena), 3-layer parallax, cartoon hazards, mini-arena framing for bosses, visible goal lights, and biome lighting (Atmosphere + ColorCorrection + Bloom).

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

### Enemy folklore (roles kept)

Hangover Pinchers, Stolen-Sunglasses Crab, King of the Tide Pool · Influencer Stick, HOA Binder Karen · Drive-Thru Gator (collar beat) · Rattle Cottonmouth, Collared Oil Gator, Fire-Breathing Lizard · Cheap Hazmat Grunts, Mark Drones, Sample Tossers, Barrel Rollers · **The Spillfather** (slam / summon / arena slick). Turtles always allies.

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
