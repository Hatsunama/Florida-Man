# Florida Man — Publish Checklist (Phase 6)

**Experience name:** Florida Man  
**Tagline:** *It IS Florida… Anything is possible in the swamp I guess.*

## Marketplace / Creator Hub

### Thumbnails & icons (upload in Creator Dashboard)

| Asset | Size | Notes |
|-------|------|-------|
| Icon | **512×512** | Bonfire + flip-flop silhouette, Florida Dew green accent |
| Thumbnails | **1920×1080** (up to 10) | Hub dawn, Crab King tele, Spillfather, turtle rescue, newspaper card |
| Feature graphic (optional) | 1920×1080 | Same as primary thumb |
| Loading / splash | Match game LoadingGui colors | Procedural OK until art pack |

Repo has no final marketplace PNGs yet — author in Studio or Blender per `ART_PIPELINE.md`, then upload. Placeholder: capture Play screenshots after `rojo serve`.

### Description copy (paste-ready)

> **Florida Man** is a 2.5D side-scroll roguelite of absurdist headlines and swamp justice. Wake up after the last honest night of your life — crabs stole your **Cold One** (**Florida Dew**, a heal can — *not* alcohol). Dual personas, item drafts, weapon loadouts, and Captain Steve (the pelican) guide you through 20 stages against **GulfGulp Energy** to save the turtles.
>
> Fight Beach Crabs, Drive-Thru Gators, and the Spillfather. Unlock personas, smash extras for **Sunburn** upgrades, and chase the sunrise credits.
>
> Keyboard + gamepad + touch. Soft launch KPIs: first-run tutorial ≤60s; aim D1 return with meta unlocks.

### Maturity / content notes (Roblox questionnaire)

| Topic | Answer |
|-------|--------|
| Violence | **Cartoon / stylized combat** — neon telegraphs, Part silhouettes, no gore |
| Blood | None |
| Alcohol | **No** — Cold One is **Florida Dew** (soda/heal buff). Explicit copy in-game |
| Drugs / controlled substances | **No** |
| Gambling | No real-money gambling; roguelite drafts only |
| Strong language | Mild absurdist comedy; keep Teen-friendly |
| User-generated | Standard Roblox chat filters apply |

### Community Standards

- No phishing, scams, or paid random items that violate Policy.
- No real-world alcohol/drug glorification (Florida Dew framing required).
- Respect IP: all characters/story original; no scraped assets.
- DataStore meta only (deaths, sunburn, unlocks, settings) — no selling meta currency for Robux without compliance review.

## Rojo → publish steps

1. `git pull` on your machine; repo path e.g. `…/Florida-Man`
2. `rojo serve` (default `localhost:34872`) **or** rebuild place:
   ```bash
   rojo build -o FloridaMan.rbxlx
   ```
3. Open `FloridaMan.rbxlx` in Roblox Studio (or connect Rojo plugin live).
4. File → Publish to Roblox → create/update Experience.
5. Enable **Studio Access to API Services** for DataStore testing; published places get real DataStores.
6. Set Experience settings: genre Adventure, devices Phone/Tablet/Computer/Console as tested.
7. **StreamingEnabled:** recommended `true` on Workspace for long stages (document only if not flipped in place file — enable in Studio before public).
8. Soft launch: private/friends → measure FTUE → public.

## Performance notes

| Item | Status |
|------|--------|
| Telegraph Debris | Legacy path replaced with **`FM_TelegraphPool`** reuse in `EnemyService` |
| Enemy pooling | **`FM_EnemyPool`** parks common trash on Clear/death; bosses destroyed |
| StreamingEnabled | **Recommend ON** for Act4 barge length / part count |
| Part budgets | See `ART_PIPELINE.md` LOD sheet — procedural Parts still heavy on low-end |
| SoundGroups | Phase 5 AudioDirector buses — keep Master ≤1 |

## Soft launch KPIs

| KPI | Target | How to read |
|-----|--------|-------------|
| **FTUE 60s** | ≥70% reach first crab kill + Cold One awareness without coaching | Session length to stage1 progress / funnel toast markers |
| **D1 return** | Track unique players returning next UTC day | Creator analytics + MetaService `bestStageIndex` / deaths |
| Softlocks / run | ≤3 per full clear (Phase 5 hunt) | Bug reports |
| Crash / disconnect | Investigate if >2% sessions | Analytics |

Instrument later: remote `TelemetryBeat` optional; for soft launch, Creator Dashboard retention + manual playtests suffice.

## Pre-flight smoke

- [ ] `./scripts/check_invariants.sh` green
- [ ] Hub spawn at Flame; E starts run
- [ ] Cold One walkover; mobile buttons if TouchEnabled
- [ ] Shake toggle persists after rejoin (DataStore or memory)
- [ ] Draft shows Florida Forecast toast when |daily luck| ≥1%
- [ ] No Studio left open by automation agents

## Credits line for page

Built with Rojo + Luau. Inspired by *Skul: The Hero Slayer* combat readability — original Florida Man story/setting.
