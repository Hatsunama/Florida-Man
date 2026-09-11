> Historical planning/reference document. Current implementation and release decisions use [IMPLEMENTATION_PROGRESS](IMPLEMENTATION_PROGRESS.md) and [RELEASE_ACCEPTANCE](RELEASE_ACCEPTANCE.md). Claims below have not been re-certified for the repaired source.

# Florida Man — Balance Sheet (Phase 6)

Companion to `src/shared/Balance.lua`. Numbers are design targets for **readable Skul-like combat**, not sponges.

## Starter DPS (Common Beach Burnout + Bare Hands)

| Term | Value |
|------|------:|
| Persona `attackDamage` | 12 |
| Weapon Bare Hands `damage` | 10 |
| Hit formula | `(12 + (10-10)*0.65) * damageMult * movesetMul * rarityMult` |
| Common / no items hit | **~12** |
| Combo finisher (~1.35 mul typ.) | **~16** |
| Attacks / sec (recovery ~0.22 / atkSpeed) | ~3–4 |
| Rough sustained DPS | **~36–48** |

With Flip-Flop (+2 weapon dmg → +1.3): hit ~13.3. Rare persona (+15%): ~15.3.

## Act 1 enemy HP (after Phase 6 retune)

`scaled = floor(base * (1 + 0.09 * stageIndex) * minibossMult)`

| Enemy | Base HP | Stage 1 scaled | Hits @12 dmg |
|-------|--------:|---------------:|-------------:|
| Beach Crab | 24 | ~26 | ~3 |
| Sand Flea | 16 | ~17 | ~2 |
| Hermit Crab | 34 | ~37 | ~3–4 |
| Crab King (MB) | 85 | ~85×1.09×0.88 ≈ **81** | ~7 |
| Angry Tourist (st2) | 36 | ~42 | ~4 |
| Slushie King (st3 MB) | 100 | ~100×1.27×0.88 ≈ **112** | ~9 |

**Act1 not spongy:** trash dies in 2–4 connects; minibosses teach dodge, not DPS checks.

## Later bands (HP mult only)

| Stage | HP mult (0.09/idx) | Max hostiles |
|------:|-------------------:|-------------:|
| 5 | 1.45 | 3 |
| 10 | 1.90 | 3 |
| 15 | 2.35 | 4 |
| 20 Spillfather | 2.80 × 340 base ≈ **952** phased | boss + adds |

Phases chunk Spillfather (~66% / 33% thresholds) so the bar never feels like one sponge.

## Daily luck modifier

`Balance.DailyLuckBonus()` → **±0.05** luck additive on `Items.RollDraft` (UTC date seed).

- Documented toast: `Florida Forecast: ±N% draft luck today`
- Does **not** change combat damage — drafts only.

## Retune log (Phase 6)

- `ENEMY_HP_PER_STAGE` 0.10 → **0.09**
- BeachCrab 26 → **24**, HermitCrab 38 → **34**
- Act1–2 miniboss mults unchanged (0.88 / 0.92 from Phase 5)

## Nightly sim note (manual)

Until codegen exists: pick stage index → `EstimateScaledEnemyHp` vs `EstimateStarterHitDamage` × expected connects before telegraph. Target: stage 1 crab TTK ≤ 1.2s of swing uptime.

## N3 catalog honesty (2026-09-04)

| Change | Value |
|--------|-------|
| Ranged pierce cap | **2** hits (`Constants.RANGED_PIERCE_HITS`); thrown remains **1** |
| BonfireEmber | `special=ember` → **+25%** damage for **2.5s** after dodge |
| GREASY set | Still **+15 HP**; now real oil resist (milder slick slow `0.88`, half fryer/slick/pipe hazard dmg) |
| HUMID set | Text matches **+5% dodge CDR** (`dodgeBonus=0.05`) + **+8 HP** |
| hoaCone | Damage tick **3** / ~0.85s (was décor-only) |
| Weapon unlocks | All **28** catalog ids reachable in-run (stage clear table) |
| Act 3–4 density | MaxHostiles **3** through stage 12, **4** from 13+ — telegraph budget unchanged |

