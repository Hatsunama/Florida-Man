# Florida Man

**Tagline:** *It IS Florida… Anything is possible in the swamp I guess.*

A playable Roblox **2.5D side-scroll roguelite** inspired by *Skul: The Hero Slayer* — absurdist Florida Man headlines, dual personas, weapon loadouts, item drafts, and a fight against **GulfGulp Energy** to save the turtles.

Wake on a beach after dancing around a bonfire. Crabs stole your **Cold One** (**Florida Dew** — a heal/buff can, *not* alcohol). Fight through a long parody headline campaign, unlock mutant wildlife personas and Florida-nonsense weapons, and take down **The Spillfather**.

## Requirements

- Roblox Studio
- Rojo 7.7+ (`rojo --version`)
- Rokit optional (`rokit.toml` pins Rojo)
- Git

Refresh PATH after installs:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
```

## Open in Studio (Rojo)

1. Open repo folder, e.g. `C:\Users\<you>\Projects\Florida-Man`
2. Run `rojo serve` at the repo root
3. In Roblox Studio, open a place and connect the **Rojo plugin** to `localhost:34872`
4. Press Play. Touch the **bonfire** (or press **E**) to start

Rebuild place file:

```powershell
rojo build -o FloridaMan.rbxlx
```

## Controls

| Action | Keyboard | Xbox |
|--------|----------|------|
| Move (lane) | A/D or ←/→ | Left stick |
| Jump (coyote + variable) | Space | A |
| Attack (3-hit combo) | Click / J | X / RT |
| Skill | K | Y / LT |
| Swap persona (+ swap attack) | Q | B |
| Dodge dash (i-frames + trail) | Left Shift | RB |
| Interact (bonfire / Captain Steve) | E | LB |

Movement is a **custom client 2.5D controller** (accel/decel, coyote jump, lane Z lock, spring camera). Default Humanoid WalkSpeed is zeroed so it does not fight the camera.

## Campaign arc (20 stages + hub)

Beach → boardwalk/town → swamp conspiracy → GulfGulp facilities → offshore → finale.

1. Daytona Hangover Beach (Cold One, Crab King)
2. Boardwalk Chaos
3. Gas Station of Legends (Slushie King, Golf Cart Bandit)
4. Strip Mall Showdown (HOA Hydra)
5. Drive-Thru Disaster (Drive-Thru Gator)
6. Canal Run
7. The Swamp Shift (mutants tagline)
8. Cypress Cathedral
9. Sludge Bayou
10. Conspiracy Shack
11. Turtle Beach / Red Tide (rescue turtles)
12. Nest Guard Night
13. GulfGulp Gate
14. Mutant Lab Wing
15. Pipe Gauntlet (Rig Overlord)
16. Loading Dock Riot
17. Barge Crossing
18. Oil Platform Approach
19. Helipad Hysteria
20. GulfGulp Rig — **The Spillfather**

Between stages: BREAKING newspaper → 3-item draft (pick 1). Inscriptions HUMID/FERAL/LUCKY/GREASY/HEROIC/CHAOS — 3 matching = set bonus.

Death → bonfire. After first death: +1 starting item slot. Smash personas at Captain Steve for Sunburn; upgrade rarity Common→Rare→Unique→Legendary.

## Content counts

| Catalog | Count |
|---------|------:|
| Playable stages | **20** |
| Personas (dual kit) | **8** |
| Power-ups / items | **28** |
| Weapons | **28** |
| Enemies (unique behaviors) | **34** |

### Personas (8)

Beach Burnout, Crab King, Gator Hauler, Snake Charmer, Golf Cart Bandit, Fireworks Enthusiast, Lizard Breath, Turtle Paladin.

### Weapons (sample)

Flip-Flop, Lawn Dart, Golf Club, Gator Wrestle Gloves, Roman Candle, Snake Lasso, Spill Skimmer, Pool Noodle, Net Gun, Finale Rocket, and more Florida nonsense (melee / ranged / thrown).

### Enemy behaviors

chase, charger, spitter, burrower, hopper, summoner, puddle/oil slicks, firearc, scuttle (crabs), tank.

## Premium systems rewritten

- `MovementController` — client-authoritative 2.5D mover
- `CameraController` — deadzone + spring dampening + screen shake
- `EnemyFactory` — welded multi-part silhouettes (crabs with 6-leg walk cycle + claw snap); no orphan Anchored accents
- `EnemyService` — behavior AI + hit flash + particle death poof
- `Weapons` catalog + equip progression along the arc
- `WorldBuilder` — parallax layers, biome Atmosphere/CC/Bloom/DoF, audio hook Sounds
- `CombatService` / `VFX` helpers

## Layout

```
default.project.json
src/shared/   Personas Items Weapons Stages Enemies Constants Remotes Util Types
src/server/   GameService WorldBuilder EnemyService EnemyFactory CombatService
src/client/   Controllers (Movement Camera Input VFX) UI (HUD Newspaper ItemDraft …)
```

## Content policy

- No drugs / intoxication gameplay
- No real alcohol brands or drinking — Cold One = Florida Dew heal can; hangover = slow status only
- Cartoon poof combat; no gore; turtles always allies
- Parody headlines only; no realistic firearms

## Lore

- Fire lizards + Lizard Breath persona
- Gators = GulfGulp science experiments (radio collars, sludge armor)
- Turtles always rescued
- Captain Steve: "It IS Florida… Anything is possible in the swamp I guess."
