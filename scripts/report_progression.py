"""Read catalog declarations only; no Roblox code or external dependencies execute."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

def read(name):
    return (ROOT / name).read_text(encoding='utf-8-sig')

def blocks(text):
    return [(m.group(1), m.group(2)) for m in re.finditer(r'\{\s*id\s*=\s*"([^"]+)"(.*?)\n?\s*\}', text, re.S)]

def field(body, key):
    match = re.search(r'\b' + re.escape(key) + r'\s*=\s*"([^"]*)"', body)
    return match.group(1) if match else ''

items = blocks(read('src/shared/Items.lua'))
weapons = blocks(read('src/shared/Weapons.lua'))
stages = {m.group(1): int(m.group(2)) for m in re.finditer(r'id\s*=\s*"([^"]+)"\s*,\s*index\s*=\s*(\d+)', read('src/shared/Stages.lua'))}
drops = {m.group(1): re.findall(r'"([^"]+)"', m.group(2)) for m in re.finditer(r'(\w+)\s*=\s*\{([^}]+)\}', read('src/shared/ProgressionCatalog.lua'))}
sets = {}
for name, body in items:
    sets.setdefault(field(body, 'inscription'), []).append(name)
lines = [
    '# Progression catalog and power reference', '',
    'Catalog counts, inscription membership, and weapon routes are parsed from current declarations by `scripts/report_progression.py`. Persona routes and numeric contracts are a manually reviewed source snapshot from 2026-09-04. This is a source mapping, not a played-through campaign or a DPS measurement. The deterministic inventory suite separately checks legal grants, set construction, and weapon coverage.', '',
    f'Catalog: {len(items)} items, {len(weapons)} weapons, {len(stages)-1} playable stages plus hub.', '',
    '## Distinct inscription members', '', '| Set | Count | Item IDs |', '|---|---:|---|',
]
for tag, names in sorted(sets.items()):
    lines.append(f'| {tag} | {len(names)} | {", ".join(names)} |')
lines += ['', 'Every set has at least three distinct members. One copy of each item is allowed per run. Capacity starts at three and grows to four/five/six in stages 6/11/16. Replacing an owned slot remains available at capacity.', '',
          '## Permanent weapon unlocks', '', '| Stage | Granted weapon IDs |', '|---|---|',
          '| Starter | BareHands, FlipFlopSlap |']
for stage, ids in sorted(drops.items(), key=lambda pair: stages.get(pair[0], 999)):
    lines.append(f'| {stages.get(stage, "?")} · {stage} | {", ".join(ids)} |')
lines += ['', 'Stage rewards share the authoritative completion ledger. FinaleRocket is retained and can be selected on the next run. Unlocking a weapon does not automatically equip it.', '',
          '## Persona acquisition and selection', '', '| Persona | Acquisition | Selection and retention |', '|---|---|---|']
routes = [
    ('BeachBurnout','Starter'), ('CrabKing','Crab King defeated, stage 1'),
    ('GolfCartBandit','Slushie King defeated or stage 3 cleared'), ('GatorHauler','Drive-Thru Gator defeated, stage 5'),
    ('SnakeCharmer','Cottonmouth defeated; first regular wave in stage 6'), ('LizardBreath','Fire Lizard defeated; first regular wave in stage 7'),
    ('TurtlePaladin','Complete a stage turtle rescue objective; first in stage 11'),
    ('FireworksEnthusiast','Finale completion, with boss defeated and all required turtles rescued'),
]
for persona, route in routes:
    lines.append(f'| {persona} | {route} | Choose either hub slot; ownership, tier, and selection persist |')
lines += ['', '## Numeric power contracts', '', '| Rarity | Damage multiplier | Skill cooldown multiplier | Cost from previous tier | Total cost from Common |', '|---|---:|---:|---:|---:|',
          '| Common | 1.00 | 1.00 | — | 0 |', '| Rare | 1.15 | 0.92 | 20 | 20 |', '| Unique | 1.30 | 0.86 | 45 | 65 |', '| Legendary | 1.50 | 0.80 | 90 | 155 |', '',
          'Shield capacity and its 18 HP heal remain fixed. Item damage bonuses contribute additively as `damageBonus / 20`, then persona rarity multiplies attack and skill damage. The HEROIC set heals 6% of accepted damage, not attempted or overkill damage.', '',
          '| Stage | Base enemy HP multiplier | Enemy damage multiplier | Simultaneous hostile cap | Item capacity |', '|---:|---:|---:|---:|---:|']
for index in (1, 3, 5, 6, 11, 16, 20):
    lines.append(f'| {index} | {1+.09*index:.2f} | {1+.075*index:.3f} | {2 if index<=2 else 3 if index<=12 else 4} | {min(6,3+(index-1)//5)} |')
lines += ['', 'Miniboss HP has an additional act modifier: 0.88 in act 1, 0.92 in act 2, and 1.00 later. Runtime rounds enemy HP/damage; listed multipliers do not imply exact displayed integer health or encounter duration.', '',
          '## Acceptance still needed', '', 'Use this mapping to exercise each acquisition, deliberate equip, effect, death, new run, and fresh-process rejoin. Measure legal combined builds, server action rate limits, projectile travel, defensive uptime, and actual encounter pacing in Studio; source counts cannot establish those outcomes.', '']
output = ROOT / 'docs' / 'CONTENT_PROGRESSION_MATRIX.md'
output.write_text('\n'.join(lines), encoding='utf-8')
print(str(output))
