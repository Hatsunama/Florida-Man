# Progression catalog and power reference

Catalog counts, inscription membership, and weapon routes are parsed from current declarations by `scripts/report_progression.py`. Persona routes and numeric contracts are a manually reviewed source snapshot from 2026-09-04. This is a source mapping, not a played-through campaign or a DPS measurement. The deterministic inventory suite separately checks legal grants, set construction, and weapon coverage.

Catalog: 28 items, 28 weapons, 20 playable stages plus hub.

## Distinct inscription members

| Set | Count | Item IDs |
|---|---:|---|
| CHAOS | 6 | IHeartFLShirt, LawnDartCharm, HOACitation, CondoPass, JetSkiKey, HeadlinePressPass |
| FERAL | 4 | LiveBait, GatorSkinWallet, CypressCharm, BonfireEmber |
| GREASY | 5 | GasStationTaquito, RadioCollar, LabBadge, MustardPacket, OilProofBoots |
| HEROIC | 5 | CrackedVisor, TurtleSticker, SpillAbsorbent, SeashellShield, RedTideFilter |
| HUMID | 5 | FlipFlops, ExpiredSunscreen, NoveltyMug, MosquitoNet, DewKoozie |
| LUCKY | 3 | LuckyPenny, PelicanWhistle, TurtleSnack |

Every set has at least three distinct members. One copy of each item is allowed per run. Capacity starts at three and grows to four/five/six in stages 6/11/16. Replacing an owned slot remains available at capacity.

## Permanent weapon unlocks

| Stage | Granted weapon IDs |
|---|---|
| Starter | BareHands, FlipFlopSlap |
| 1 · DaytonaHangover | FlipFlopSlap, CoolerLid |
| 2 · BoardwalkChaos | PoolNoodle, NewspaperRoll |
| 3 · GasStationLegends | GolfClub, TrafficCone |
| 4 · StripMallShowdown | HOAClipboard, BeachUmbrella |
| 5 · DriveThruDisaster | GatorWrestleGloves, ShoppingCart |
| 6 · CanalRun | KayakPaddle, WaterBalloonSling |
| 7 · SwampShift | SnakeLasso, FishSmack |
| 8 · CypressCathedral | TikiTorch, LawnDart |
| 9 · SludgeBayou | SpillSkimmer |
| 10 · ConspiracyShack | Skateboard, PelicanBeakReplica |
| 11 · TurtleBeach | NetGun |
| 13 · GulfGulpGate | FireExtinguisher |
| 14 · LabWing | BugZapper |
| 15 · PipeGauntlet | OilBarrelLid |
| 17 · BargeCrossing | BoogieBoard |
| 18 · OilPlatformApproach | SludgeHose |
| 19 · HelipadHysteria | RomanCandle |
| 20 · GulfGulpRig | FinaleRocket |

Stage rewards share the authoritative completion ledger. FinaleRocket is retained and can be selected on the next run. Unlocking a weapon does not automatically equip it.

## Persona acquisition and selection

| Persona | Acquisition | Selection and retention |
|---|---|---|
| BeachBurnout | Starter | Choose either hub slot; ownership, tier, and selection persist |
| CrabKing | Crab King defeated, stage 1 | Choose either hub slot; ownership, tier, and selection persist |
| GolfCartBandit | Slushie King defeated or stage 3 cleared | Choose either hub slot; ownership, tier, and selection persist |
| GatorHauler | Drive-Thru Gator defeated, stage 5 | Choose either hub slot; ownership, tier, and selection persist |
| SnakeCharmer | Cottonmouth defeated; first regular wave in stage 6 | Choose either hub slot; ownership, tier, and selection persist |
| LizardBreath | Fire Lizard defeated; first regular wave in stage 7 | Choose either hub slot; ownership, tier, and selection persist |
| TurtlePaladin | Complete a stage turtle rescue objective; first in stage 11 | Choose either hub slot; ownership, tier, and selection persist |
| FireworksEnthusiast | Finale completion, with boss defeated and all required turtles rescued | Choose either hub slot; ownership, tier, and selection persist |

## Numeric power contracts

| Rarity | Damage multiplier | Skill cooldown multiplier | Cost from previous tier | Total cost from Common |
|---|---:|---:|---:|---:|
| Common | 1.00 | 1.00 | — | 0 |
| Rare | 1.15 | 0.92 | 20 | 20 |
| Unique | 1.30 | 0.86 | 45 | 65 |
| Legendary | 1.50 | 0.80 | 90 | 155 |

Shield capacity and its 18 HP heal remain fixed. Item damage bonuses contribute additively as `damageBonus / 20`, then persona rarity multiplies attack and skill damage. The HEROIC set heals 6% of accepted damage, not attempted or overkill damage.

| Stage | Base enemy HP multiplier | Enemy damage multiplier | Simultaneous hostile cap | Item capacity |
|---:|---:|---:|---:|---:|
| 1 | 1.09 | 1.075 | 2 | 3 |
| 3 | 1.27 | 1.225 | 3 | 3 |
| 5 | 1.45 | 1.375 | 3 | 3 |
| 6 | 1.54 | 1.450 | 3 | 4 |
| 11 | 1.99 | 1.825 | 3 | 5 |
| 16 | 2.44 | 2.200 | 4 | 6 |
| 20 | 2.80 | 2.500 | 4 | 6 |

Miniboss HP has an additional act modifier: 0.88 in act 1, 0.92 in act 2, and 1.00 later. Runtime rounds enemy HP/damage; listed multipliers do not imply exact displayed integer health or encounter duration.

## Acceptance still needed

Use this mapping to exercise each acquisition, deliberate equip, effect, death, new run, and fresh-process rejoin. Measure legal combined builds, server action rate limits, projectile travel, defensive uptime, and actual encounter pacing in Studio; source counts cannot establish those outcomes.
