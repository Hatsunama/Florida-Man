"""Evaluate real Luau catalogs and pure rules; emit reviewable content/balance tables.

Color3/Vector3 constructors below retain data only. No engine, combat simulation,
physics, UI, or successful Roblox asset loading is being mocked or claimed.
"""
import argparse,csv,hashlib,json,subprocess
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def main():
    p=argparse.ArgumentParser();p.add_argument('--luau',required=True);args=p.parse_args()
    out=ROOT/'artifacts/catalog';out.mkdir(parents=True,exist_ok=True)
    prelude='local Color3={fromRGB=function(r,g,b) return {r,g,b} end}\nlocal Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}\n'
    names=['Constants','Stages','Personas','Enemies','Items','Weapons','Balance','ProgressionRules','ProgressionCatalog','Movesets','BuildRules','LayoutPlan']
    bundle=prelude
    hashes={}
    for name in names:
        path=ROOT/f'src/shared/{name}.lua';source=path.read_text(encoding='utf-8-sig');hashes[name]=hashlib.sha256(source.encode()).hexdigest()
        bundle+=f'local {name}=(function()\n{source}\nend)()\n'
    bundle+=r'''
local function encode(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' or kind=='number' then return tostring(value) end
    if kind=='string' then return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
    local entries={}
    if #value>0 then
        for _,v in value do table.insert(entries,encode(v)) end
        return '['..table.concat(entries,',')..']'
    end
    for k,v in value do if type(v)~='function' then table.insert(entries,encode(tostring(k))..':'..encode(v)) end end
    return '{'..table.concat(entries,',')..'}'
end
local bounds={}
for capacity=3,6 do
    local b={count=0}; bounds[tostring(capacity)]=b
    for _,field in {'maxHp','damageMult','speedBonus','luck','dodgeBonus'} do b[field]={min=math.huge,max=-math.huge} end
    local ids={}
    local function visit(first)
        if #ids==capacity then
            b.count+=1
            local stats=BuildRules.Compute(ids,Items,Constants)
            for field,score in stats do
                local bound=b[field]
                if score<bound.min then bound.min=score;bound.minBuild=table.clone(ids) end
                if score>bound.max then bound.max=score;bound.maxBuild=table.clone(ids) end
            end
            return
        end
        for i=first,#Items.List-(capacity-#ids)+1 do
            table.insert(ids,Items.List[i].id); visit(i+1); table.remove(ids)
        end
    end
    visit(1)
end
local layouts={}
local layoutChecks=0
for _,stage in Stages.List do
    local spans=LayoutPlan.ForStage(stage,Constants.SPAWN_X)
    local function supported(x,clearance,label)
        assert(LayoutPlan.HasSupport(spans,x,clearance),label..' unsupported: '..stage.id..' at '..tostring(x))
        layoutChecks+=1
    end
    supported(Constants.SPAWN_X,3,'Actual spawn')
    supported(stage.length-6,4,'Actual exit')
    supported(stage.length*0.48-10,5,'Midroom trigger')
    supported(stage.length*0.82,4,'Late encounter reservation')
    for _,wave in stage.waves do supported(stage.length*wave.atProgress+16,3,'Wave landing reservation') end
    for i=1,stage.rescueTurtles do supported(stage.length*(0.2+0.12*i),3,'Actual turtle spawn') end
    assert(spans[1].first==-10 and spans[#spans].last==stage.length+20,'Route endpoints: '..stage.id)
    for i,span in spans do
        assert(span.first<span.last,'Reversed span: '..stage.id)
        if i>1 then assert(spans[i-1].last==span.first,'Discontinuous span: '..stage.id) end
        if span.gap then
            assert(stage.setPiece=='canalPads' or stage.setPiece=='bargeGaps','Unexpected gap stage: '..stage.id)
            assert(span.last-span.first<=6,'Oversized gap: '..stage.id)
        end
    end
    layouts[stage.id]=spans
end
print(encode({stages=Stages.List,personas=Personas.List,enemies=Enemies.List,items=Items.List,weapons=Weapons.List,sets=Items.SetBonuses,movesets=Movesets.List,rarity=Balance.RARITY_POWER,skillCdr=Balance.RARITY_SKILL_CDR,hpScale=Balance.ENEMY_HP_PER_STAGE,damageScale=Balance.ENEMY_DMG_PER_STAGE,minibossHp=Balance.MINIBOSS_HP_ACT,unlocks=ProgressionCatalog,bounds=bounds,layouts=layouts,layoutSupportAssertions=layoutChecks}))
'''
    script=out/'evaluate.luau';script.write_text(bundle,encoding='utf-8')
    result=subprocess.run([args.luau,str(script)],cwd=ROOT,text=True,capture_output=True,encoding='utf-8',timeout=60)
    if result.returncode:raise SystemExit(result.stderr)
    data=json.loads(result.stdout);data['sourceHashes']=hashes
    (out/'catalog.json').write_text(json.dumps(data,indent=2,ensure_ascii=False),encoding='utf-8')
    rows=[]
    for persona in data['personas']:
        moves=data['movesets'][persona['id']]
        for weapon in data['weapons']:
            speed=max(.55,persona['attackSpeed']*weapon['speed'])
            seconds=sum(m['recovery']/speed for m in moves)
            for rarity,power in data['rarity'].items():
                hit=(persona['attackDamage']+(weapon['damage']-10)*.65)*(1+power)
                damage=sum(hit*m['dmgMul'] for m in moves)*(1.05 if weapon['kind']=='thrown' else 1)
                rows.append({'persona':persona['id'],'weapon':weapon['id'],'rarity':rarity,'cycleSeconds':round(seconds,4),'cycleDamageBeforeMitigation':round(damage,3),'uninterruptedSingleTargetDPS':round(damage/seconds,3),'skillCooldownSeconds':round(persona['skillCooldown']*(1-data['skillCdr'][rarity]),3),'skillKind':persona['skillKind'],'range':weapon['range']})
    with (out/'build-cycles.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    content=['# Executed catalog and connection manifest','','Generated by `scripts/export_catalog.py` from current Luau definitions. Color and size constructors are data adapters. This does not demonstrate engine reachability or visual quality.','','## Stages and objectives','','| Stage | Identity | Waves / threats | Rescue requirement | Story fact |','|---|---|---|---:|---|']
    enemy_ids={e['id'] for e in data['enemies']}; persona_ids={p['id'] for p in data['personas']}
    for stage in data['stages']:
        waves=stage['waves'] if isinstance(stage['waves'],list) else []
        assert all(w['enemyId'] in enemy_ids for w in waves)
        for key in ['boss','miniboss']:
            if stage.get(key):assert stage[key] in enemy_ids
        if stage.get('unlockPersona'):assert stage['unlockPersona'] in persona_ids
        content.append(f"| {stage['index']} {stage['name']} | {stage['setPiece']} | {sum(w['count'] for w in waves)} regular + {stage.get('miniboss') or stage.get('boss') or 'no boss'} | {stage['rescueTurtles']} | {stage['storyBeat']} |")
    content+=['','## Personas','','All owned personas can be selected into two distinct hub slots. Unlocks, rarity and selection persist. Items last for the current run.','','| Persona | Unlock | Skill |','|---|---|---|']
    for p in data['personas']:content.append(f"| {p['name']} | {p['unlockHint']} | {p['skillKind']}: {p['skillDescription']} |")
    content+=['','## Weapons','','Every earned weapon persists and is selectable; stage completion does not auto-equip it. Generic visual families are intentional procedural fallbacks.','','| Weapon | Unlock stage | Mechanic | Visual family |','|---|---|---|---|']
    unlocks={w:s for s,ws in data['unlocks'].items() for w in ws};unlocks['BareHands']='Starter'
    for w in data['weapons']:content.append(f"| {w['name']} | {unlocks.get(w['id'],'Starter')} | {w['kind']} / {w.get('secondaryEffect','none')} | {w['vfx']} |")
    content+=['','## Items','','All 28 have a draft route, unique ownership, replacement at capacity, and effects computed from the catalog. The item inventory grows from 3 to 6 without requiring death.','','| Item | Set | Accepted effect |','|---|---|---|']
    for item in data['items']:content.append(f"| {item['name']} | {item['inscription']} | {item['statText']} |")
    content+=['','## Enemy catalog','','| Enemy | Role | Shape | Base HP |','|---|---|---|---:|']
    for e in data['enemies']:content.append(f"| {e['name']} | {e['behavior']} | {e['shape']} | {e['hp']} |")
    (ROOT/'docs/CATALOG_IMPLEMENTATION.md').write_text('\n'.join(content)+'\n',encoding='utf-8')
    balance=['# Executed balance bounds','','The generated CSV contains all 896 persona × weapon × rarity combinations. Its DPS is an uninterrupted single-target upper bound before integer rounding, enemy-specific effects, misses, obstruction, travel, interrupts and skill use. It is not measured combat performance. Ranged pierce can affect several targets; throws receive their actual 1.05 multiplier. Skills have different uptime/target rules and are intentionally not flattened into one misleading DPS number.','','## Legal item combinations','','These exhaustive bounds execute the same `BuildRules.Compute` used at runtime. Each extremum can belong to a different build. Set reachability is tested separately.','','| Slots | Enumerated unique builds | HP range | Damage multiplier range | Speed bonus range | Luck range |','|---:|---:|---|---|---|---|']
    for cap,b in sorted(data['bounds'].items(),key=lambda entry:int(entry[0])):balance.append(f"| {cap} | {b['count']} | {b['maxHp']['min']}–{b['maxHp']['max']} | {b['damageMult']['min']:.2f}–{b['damageMult']['max']:.2f} | {b['speedBonus']['min']}–{b['speedBonus']['max']} | {b['luck']['min']:.2f}–{b['luck']['max']:.2f} |")
    balance+=['','## Stage scaling and population','','Full demand is queued within the encounter cap. Wave count is not the count simultaneously alive. Midroom and boss add demand is additional.','','| Stage | HP multiplier | Damage multiplier | Authored regular count |','|---|---:|---:|---:|']
    for stage in data['stages']:
        waves=stage['waves'] if isinstance(stage['waves'],list) else []
        balance.append(f"| {stage['index']} {stage['id']} | {1+data['hpScale']*stage['index']:.2f} | {1+data['damageScale']*stage['index']:.3f} | {sum(w['count'] for w in waves)} |")
    balance+=['','## Tuning decisions and next measurements','','- Three unique pieces can form every set. TurtleSnack now fills the third LUCKY member; duplicates do not substitute for set diversity.','- Defensive reductions multiply once, then damage rounds once with a minimum of 1 for an accepted positive hit. A consumed shell can fully absorb a hit. This prevents rounding three absorb items into immunity.','- Slow attacks retain their combo through their own recovery; grace is measured after recovery ends.','- Existing HP/damage curves are retained pending real traces. Human first-three-stage time, failed attempts, target-device frame time, summon uptime and set acquisition probability remain measurement gates.','- Full data and exact extremizing build IDs: artifacts/catalog/catalog.json. Recreate CSV and data with the generator; do not manually edit exported numbers.']
    (ROOT/'docs/BALANCE_IMPLEMENTATION.md').write_text('\n'.join(balance)+'\n',encoding='utf-8')
    print(f'Exported {len(data["stages"])} stages, {len(rows)} attack cycles, {sum(b["count"] for b in data["bounds"].values())} legal item combinations; {data["layoutSupportAssertions"]} layout support assertions passed.')

if __name__=='__main__':main()
