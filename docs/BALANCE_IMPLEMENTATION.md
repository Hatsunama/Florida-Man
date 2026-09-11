# Executed balance bounds

The generated CSV contains all 896 persona × weapon × rarity combinations. Its DPS is an uninterrupted single-target upper bound before integer rounding, enemy-specific effects, misses, obstruction, travel, interrupts and skill use. It is not measured combat performance. Ranged pierce can affect several targets; throws receive their actual 1.05 multiplier. Skills have different uptime/target rules and are intentionally not flattened into one misleading DPS number.

## Legal item combinations

These exhaustive bounds execute the same `BuildRules.Compute` used at runtime. Each extremum can belong to a different build. Set reachability is tested separately.

| Slots | Enumerated unique builds | HP range | Damage multiplier range | Speed bonus range | Luck range |
|---:|---:|---|---|---|---|
| 3 | 3276 | 100–167 | 1.00–2.15 | -1–9 | 0.00–0.52 |
| 4 | 20475 | 100–185 | 1.00–2.48 | -1–11 | 0.00–0.67 |
| 5 | 98280 | 100–200 | 1.00–2.73 | -1–12 | 0.00–0.77 |
| 6 | 376740 | 100–217 | 1.00–2.93 | -1–13 | 0.00–0.87 |

## Stage scaling and population

Full demand is queued within the encounter cap. Wave count is not the count simultaneously alive. Midroom and boss add demand is additional.

| Stage | HP multiplier | Damage multiplier | Authored regular count |
|---|---:|---:|---:|
| 0 Hub | 1.00 | 1.000 | 0 |
| 1 DaytonaHangover | 1.09 | 1.075 | 6 |
| 2 BoardwalkChaos | 1.18 | 1.150 | 7 |
| 3 GasStationLegends | 1.27 | 1.225 | 5 |
| 4 StripMallShowdown | 1.36 | 1.300 | 6 |
| 5 DriveThruDisaster | 1.45 | 1.375 | 5 |
| 6 CanalRun | 1.54 | 1.450 | 8 |
| 7 SwampShift | 1.63 | 1.525 | 10 |
| 8 CypressCathedral | 1.72 | 1.600 | 8 |
| 9 SludgeBayou | 1.81 | 1.675 | 8 |
| 10 ConspiracyShack | 1.90 | 1.750 | 8 |
| 11 TurtleBeach | 1.99 | 1.825 | 7 |
| 12 NestGuard | 2.08 | 1.900 | 7 |
| 13 GulfGulpGate | 2.17 | 1.975 | 8 |
| 14 LabWing | 2.26 | 2.050 | 9 |
| 15 PipeGauntlet | 2.35 | 2.125 | 8 |
| 16 LoadingDock | 2.44 | 2.200 | 9 |
| 17 BargeCrossing | 2.53 | 2.275 | 8 |
| 18 OilPlatformApproach | 2.62 | 2.350 | 9 |
| 19 HelipadHysteria | 2.71 | 2.425 | 9 |
| 20 GulfGulpRig | 2.80 | 2.500 | 7 |

## Tuning decisions and next measurements

- Three unique pieces can form every set. TurtleSnack now fills the third LUCKY member; duplicates do not substitute for set diversity.
- Defensive reductions multiply once, then damage rounds once with a minimum of 1 for an accepted positive hit. A consumed shell can fully absorb a hit. This prevents rounding three absorb items into immunity.
- Slow attacks retain their combo through their own recovery; grace is measured after recovery ends.
- Existing HP/damage curves are retained pending real traces. Human first-three-stage time, failed attempts, target-device frame time, summon uptime and set acquisition probability remain measurement gates.
- Full data and exact extremizing build IDs: artifacts/catalog/catalog.json. Recreate CSV and data with the generator; do not manually edit exported numbers.
