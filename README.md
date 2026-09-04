# Florida Man

**Tagline:** *It IS Florida… Anything is possible in the swamp I guess.*

A playable Roblox **2.5D side-scroll roguelite** inspired by *Skul: The Hero Slayer* — absurdist Florida Man headlines, dual personas, item drafts, and a fight against **GulfGulp Energy** to save the turtles.

Wake on a beach after dancing around a bonfire. Crabs stole your **Cold One** (**Florida Dew** — a heal/buff can, *not* alcohol). Fight through parody headline stages, unlock mutant wildlife personas, and take down **The Spillfather**.

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

## Controls

| Action | Keyboard | Xbox |
|--------|----------|------|
| Move | WASD | Left stick |
| Jump | Space | A |
| Attack (3-hit combo) | Click / J | X / RT |
| Skill | K | Y / LT |
| Swap persona (+ swap attack) | Q | B |
| Dodge (i-frames) | Left Shift | RB |
| Interact (bonfire / Captain Steve) | E | LB |

## Run flow

1. Hub dawn bonfire — Captain Steve upgrades, start at flame
2. Daytona Hangover Beach — crabs, Florida Dew Cold One, Crab King
3. Gas Station of Legends — tourists / slushies → Golf Cart Bandit
4. Drive-Thru Disaster — Drive-Thru Gator (radio collar) → Gator Hauler
5. The Swamp Shift — snakes, Oil Gators, Fire Lizards + Captain Steve sting
6. Turtle Beach / Red Tide — rescue turtles → Turtle Paladin
7. GulfGulp Rig — The Spillfather + credits

Between stages: BREAKING newspaper → 3-item draft (pick 1). Inscriptions HUMID/FERAL/LUCKY/GREASY/HEROIC/CHAOS — 3 matching = set bonus.

Death → bonfire. After first death: +1 starting item slot. Smash personas at Captain Steve for Sunburn; upgrade rarity Common→Rare→Unique→Legendary.

## Personas (8)

Beach Burnout, Crab King, Gator Hauler, Snake Charmer, Golf Cart Bandit, Fireworks Enthusiast, Lizard Breath, Turtle Paladin.

## Items (15)

Flip-Flops, Cracked Visor, Live Bait, Expired Sunscreen, I♥FL Shirt, Novelty Mug, Turtle Sticker, Gas-Station Taquito, Lawn Dart, HOA Citation, Lucky Penny, Gator-Skin Wallet, Radio Collar, Spill Absorbent, Lab Badge.

## Layout

```
default.project.json
rokit.toml
src/shared/   Personas Items Stages Enemies Constants Remotes Util Types
src/server/   GameService WorldBuilder EnemyService
src/client/   HUD Newspaper ItemDraft Credits Tagline CaptainSteveUI Controllers
```

### Add content

- Persona: `src/shared/Personas.lua` + unlock hook in `GameService`
- Item: `src/shared/Items.lua` (auto draft pool)
- Stage: `src/shared/Stages.lua` + optional decor theme in `WorldBuilder`

## Content policy

- No drugs / intoxication gameplay
- No real alcohol brands or drinking — Cold One = Florida Dew heal can; hangover = slow status only
- Cartoon poof combat; no gore; turtles always allies
- Parody headlines only; no realistic firearms

## Lore implemented

- Fire lizards + Lizard Breath persona
- Gators = GulfGulp science experiments (radio collars, sludge armor)
- Turtles always rescued
- Captain Steve: "It IS Florida… Anything is possible in the swamp I guess."
