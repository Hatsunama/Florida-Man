# Florida Man — Layer Ownership Audit (Gen-2, Ruthless)

**Date:** 2026-09-04 (America/New_York)  
**HEAD audited:** `a28a266` (+ this commit)  
**Prior full audit:** [`AUDIT_FULL.md`](AUDIT_FULL.md) @ `8e260c8` (pre Phase 0–6)  
**Prior scorecard:** [`AUDIT_FINAL.md`](AUDIT_FINAL.md)  
**Companion plan:** [`PLAN_NEXT.md`](PLAN_NEXT.md)

**Method:** Static evidence at current HEAD after Phases 0–6. No Studio. Focus: layer ownership, leaks, false code, edge cases, options/settings, areas AUDIT_FULL skimmed.

---

## Executive scorecard (post Phase 0–6, ruthless)

| Area | Grade | One-line verdict |
|------|:-----:|------------------|
| A. Sprites / art | **C−** | In-engine Part kits + docs; still zero real MeshPart / SurfaceAppearance pipeline |
| B. Interactions / UX | **B−** | Prompts, mobile, FTUE better; toast/tagline spam; Steve shop UX thin |
| C. Movement / camera | **B** | Lane/facing locked; OilSlow attr unread on client; default R15 Animate |
| D. Combat | **B−** | CombatService owns validation/projectiles; GameService still orchestrates Do* |
| E. Enemies / AI | **B−** | Telegraph skins + pools; chase-core AI; boss phases = HP thresholds |
| F. Levels / differences | **C+** | Set-pieces/hazards differ; verb loop still walk-right / clear-gate |
| G. Story | **B** | Strong bible; delivery = Tagline/Toast/Newspaper (now correct channel) |
| H. Power scaling | **B−** | Curve + sheet exist; catalog specials / weapon.speed uneven; drafts thin |
| I. Options / settings | **C+** | Shake + CB tele only; no master/SFX mute, no rembind, no reduce-motion |
| J. Edge cases / trust | **C** | Many softlocks fixed; remotes/DataStore/PendingDamage races remain |
| K. Architecture / layers | **C** | Meta/Hazard extracted; GameService ~1674 lines god-object; Types hollow |
| L. False code | **D+** | Dead remotes, unread attrs, lying item copy, empty Types |

**Overall:** Soft-launch-capable jam with real combat ownership — **not** layer-clean, not catalog-honest, not options-complete.

---

## Layer ownership matrix

| Layer | Should own | Actual owner today | Grade |
|-------|------------|--------------------|:-----:|
| `src/shared/*` | Pure data, balance, story strings, remote **names** — no Instance mutation, no DataStore | Mostly OK. **Violations:** `Remotes.InitServer` creates Instances; `Settings.SetBool` mutates Player attrs (called from client HUD + server Meta). `Util` fine. | **B−** |
| `src/server/*Service` | Authority: damage, i-frames, meta save, spawns, hazards | Combat/Meta/Hazard/Enemy/Tutorial mostly correct. **GameService** still owns combat remotes, drafts, hub shop, waves, MidGate, Cold One, persona apply. | **C** |
| `src/client/Controllers` | Input, camera, movement prediction, VFX, tutorial UX | Good separation. **Leak:** client attack recovery buffer can diverge from server `CanAttack`; InputController opens Steve UI (OK) but also fires combat without awaiting draft lock from server state. | **B** |
| `src/client/UI` | Presentation — fire remotes, display state | Generally OK. **Leak:** HUD toggles settings locally via `Settings.Toggle` before/without waiting for server ack (a11y OK, but entitlement pattern wrong for future paid settings). CaptainSteveUI holds lastState copy of economy. | **B−** |
| Remotes | Thin events; validate on server | Thin creation OK. **Dead:** `RequestJump`. **Client-never-fired:** `EquipWeapon` (server listens). Validation uneven (draft item id checked; Smash allows equipped smash after toast). | **C** |

### Responsibility checklist (pass/fail)

| Concern | Correct layer? | Evidence |
|---------|:--------------:|----------|
| Damage / i-frames | **PASS** (server) | `CombatService.HasIFrames` table; `IFrameVFX` juice only |
| Hit validation | **PASS** | `InLaneMelee` fixed facing (point-blank ≤2.5 only) |
| Meta persist | **PASS** | `MetaService` DataStore + memory |
| Hazard tick | **PASS** | `HazardService.Tick` |
| Wave / MidGate / draft | **FAIL** | Still inside `GameService` |
| Story strings | **PASS** | `Story.lua` / `Stages.lua` |
| Remotes folder create | **SOFT FAIL** | `Remotes.InitServer` in shared (Instance mutation) |
| Settings persistence rules | **SOFT FAIL** | Defaults in shared; persist rules in Meta; toggle UX in HUD |
| Enemy pool / telegraph pool | **PASS** | `EnemyService` |
| Dialogue presentation | **PASS** (this pass) | `ShowTagline` → Tagline popup; dialogue SFX blocked |

---

## Leak table (wrong-layer / wrong-owner)

| # | Leak | Where | Risk | Severity |
|---|------|-------|------|:--------:|
| L1 | God-object run loop | `GameService.lua` ~1674 lines | Every feature regresses facing/prompts/draft | **P0** |
| L2 | Shared `Remotes.InitServer` mutates DataModel | `Remotes.lua` | Shared is not pure; tests/tools harder | **P2** |
| L3 | Shared `Settings.Toggle` used from client HUD | `HUD.lua` + `Settings.lua` | Client-authored “truth” pattern; Colorblind may desync until SyncSettings | **P2** |
| L4 | `PendingDamage` Player attributes as combat bus | `EnemyService` → `GameService` tick | Race/drop if tick lags; exploit can write attrs if replication allows | **P1** |
| L5 | `OilSlow` set on character, unread by mover | `HazardService` vs `MovementController` | Relies on `moveSpeed` push only; attr is lying signal; Hangover×Oil stacking opaque | **P1** |
| L6 | Client local attack recovery (`ATTACK_RECOVERY=0.2`) vs server moveset recovery | `InputController` / `CombatService` | Ghost swings / buffer desync | **P2** |
| L7 | CaptainSteveUI caches economy `lastState` | `CaptainSteveUI.lua` | Stale sunburn after smash if StateUpdate delayed | **P2** |
| L8 | WorldBuilder creates StageSounds + biome bed clones | `WorldBuilder.lua` | Server owns presentation audio stubs; client AudioDirector also beds → double policy | **P2** |
| L9 | Soft Z CFrame stomp in HazardService | `softFallAndLane` | Server fights client AlignPosition under lag | **P2** |
| L10 | Hub Flame proximity empty branch in GameService tick | `GameService` tick loop | Dead control-flow / noise | **P3** |
| L11 | `Types.lua` almost empty while domain types live per-module | `Types.lua` | No shared contract; false “typed codebase” | **P2** |
| L12 | UI decides when Steve panel opens (OK) but Smash/Upgrade fire without hub/inHub re-check on client | Steve UI | Server must reject mid-run (verify) | **P2** |
| L13 | Dialogue formerly on AudioDirector UI beds | Tagline/AudioCatalog | Policy violated until this pass | **P1** (fixed popup path) |
| L14 | Meta save on both `PlayerRemoving` (Meta + GameService) | Double Unload/Save | Duplicate SetAsync / race on leave | **P2** |
| L15 | `EquipWeapon` server handler, no client UI fire path | Remotes / GameService | Dead control surface; weapons unlock passively only | **P2** |

**Layer leak count (actionable L1–L15, excluding fixed L13 dialogue path):** **14** open; **1** mitigated this commit (dialogue popup).

---

## False-code inventory

| Item | Claim / presence | Reality | Verdict |
|------|------------------|---------|---------|
| `RequestJump` remote | In `Remotes.NAMES` | Never fired, never connected | **DEAD** |
| `EquipWeapon` remote | Server `OnServerEvent` | No client `FireServer` | **HALF-DEAD** |
| `Types.lua` | Typed project | 2 export aliases + `return nil` | **HOLLOW** |
| `BonfireEmber` copy | “+Damage after dodge” | `special=""` — no post-dodge hook | **LIE** |
| `GREASY` set “oil resist” | SetBonuses text | Only `hpBonus=15`; absorb is separate special | **SOFT LIE** |
| `HUMID` “dodge window feel” | Set text | Flat `dodgeBonus` scalar, not i-frame window | **SOFT LIE** |
| `weapon.speed` | Catalog field | Used in recovery divisor — OK | **LIVE** |
| `weapon.vfx` | Catalog | Wired to attr + VFX/projectiles (partial skins) | **PARTIAL** |
| Many `vfx` kinds (`grab`,`lasso`,`peck`,…) | Distinct feel | Fall through to default slash color | **CATALOG THEATER** |
| `persona.attackSpeed` | Per persona | Used in MarkAttack recovery | **LIVE** |
| `hoaCone` hazard | Stages list it | WorldBuilder prop; little/no damage verb | **DÉCOR** |
| Hub tick Flame magnitude check | Code branch | Empty body | **DEAD CODE** |
| MetaService Studio `if RunService:IsStudio()` | Block | Empty body after strip | **DEAD** |
| `SFX_SteveBeep` / `SFX_Typewriter` | Catalog + Tagline | Tagline no longer plays; AudioDirector blocks | **DEPRECATED** |
| CombatService ranged pierce comments | “pierce light” | Ranged never destroys on hit → infinite pierce until range | **BEHAVIOR ≠ COMMENT** (comments stripped; behavior remains) |
| Item specials `aggro` | LiveBait | EnemyService distance bias — OK | **LIVE** |
| `paperCut` / `radio` / `lifesteal` / `sunburnFind` / `stageHeal` / `absorb` | Catalog | Implemented in GameService paths (verify absorb resist magnitude) | **MOSTLY LIVE** |
| `antiCorp` / `badge` | Specials | Flat stats in `computeStats` only | **STAT STICKERS** |
| Rojo `Remotes` empty Folder + InitServer | Project JSON | Duplicate create pattern OK but confusing | **NOISE** |
| `default.project.json` Spawn at x=8 vs `SPAWN_X=18` | Safety pad spawn | `init.server` SpawnLocation at 8; hub teleports to 18 | **SOFT CONFLICT** |

---

## Area audits (Gen-2 depth)

### A. Sprites / art — **C−**
- EnemyFactory / WorldBuilder still `Instance.new("Part")` kits; Phase 2 docs promise Mesh pipeline not in repo.
- AnimController procedural; no authored AnimationId clips.
- HUD persona icons = colored circles, not sprites.
- **Overlook:** no atlas, no LOD, no thumbnail PNGs in repo (`PUBLISH_CHECKLIST` sizes only).

### B. Interactions — **B−**
- ProximityPrompt + E + mobile buttons exist.
- Turtle rescue: prompt + attack proximity + RescueTurtle remote — **triple path** → spam risk.
- Draft/Newspaper disable Space via GUI name checks — attack (J/mouse) still possible if InputController enabled during draft (**edge:** attack during draft UI).
- GameService `DoAttack` gates `awaitingDraft` — good; skill/swap/dodge need same audit.

### C. Movement — **B**
- lookAlong + Align* invariants hold.
- **OilSlow** attr unused on client; speed applied via `st.moveSpeed` + `applyCharacterSpeed`.
- Hangover mult stacks with Karen `SlowUntil` but not explicitly with OilSlow attr.
- Soft-fall: 1.0s gate; can loop toast if falling in pit with bad checkpoint.
- Mobile + keyboard: both write `moveX`; OK. Touch + key same frame = last writer wins in RenderStepped.

### D. Combat — **B−**
- CombatService: movesets, i-frames, shield absorb, projectiles, lingering hitbox.
- GameService still `DoAttack`/`DoSkill`/`DoSwap`/`DoDodge` — ownership split.
- Growth: CombatService ~419 lines (was orphan 22) — healthy; GameService still bloated.
- Ranged projectiles pierce all until maxDist (may be overpowered).

### E. Enemies — **B−**
- Telegraph pools + enemy park pools (Phase 6).
- BossPhase hyper armor on transition — good.
- AI still PivotTo chase; uniqueness = telegraph décor.

### F. Level differences — **C+**
| Band | Intended difference | Actual verb delta |
|------|---------------------|-------------------|
| 1–5 Hangover Coast | Teach + comedy hazards | Cold One, fryer timing, neon sticky — **best differentiated** |
| 6–10 Swamp | Pads / oil / fire | Canal pads + oil — still lane clear |
| 11–12 Turtle | Rescue gate | Count gate — good forced beat |
| 13–19 Facility | Conveyor / samples | Moving parts — readable |
| 20 Finale | 3-phase arena | Slick ring + summons — OK, not choreography |

**Overlook from AUDIT_FULL:** `scalingTier` / `platformLedges` fields under-consumed for real platforming density; SafetyFloor removed but soft-fall makes gaps low-stakes.

### G. Story — **B**
- Delivery policy (**this pass**): **all conversation = Tagline / Toast / Newspaper popups**. No dialogue VO/SFX.
- Steve lines already `ShowTagline`; Tagline typewriter is visual-only now.
- Emotional beats still non-staged (no camera scene graph).

### H. Power scaling — **B−**
- `Balance.lua` + `BALANCE_SHEET.md`: HP 0.09/stage, rarity power/CDR, daily luck ±5%.
- Draft does not validate item not already owned / slot cap before insert? (`PickDraftItem` inserts always — **slot overflow edge**).
- Weapon unlocks stage-gated map in GameService — many catalog weapons never unlock.
- Legendary FinaleRocket may be unreachable without unlock table entry.

### I. Options / settings — **C+** (AUDIT_FULL skim → now graded)
| Setting | Exists | Persisted | Notes |
|---------|:------:|:---------:|-------|
| ShakeEnabled | Yes | Meta | Camera respects |
| ColorblindTelegraphs | Yes | Meta | EnemyService stripes |
| Master / SFX / Music mute | **No** | — | Needed for combat-SFX-only policy |
| Reduce motion / hitstop off | **No** | — | |
| Key rebind | **No** | — | |
| Dialogue text speed | **No** | — | Tagline fixed 0.028 |
| Language | **No** | — | |

### J. Edge cases (explicit)

| Case | Status | Notes |
|------|--------|-------|
| DataStore fail | **Handled** | Memory fallback + warn |
| DataStore GetAsync fail mid-session | **Partial** | Uses memory[uid] if any; else defaults — can **wipe** progress appearance |
| Mid-run leave | **Handled** | Persist on PlayerRemoving (double save) |
| Double PromptTriggered | **Mitigated** | StartRun claims `runActive` immediately |
| Attack during draft UI | **Partial** | Server blocks DoAttack if awaitingDraft; client may still play swing VFX |
| Soft-fall loop | **Risk** | Checkpoint behind pit + Y<-2 every 1s → toast spam |
| MidGate 0 enemies | **Fixed P5** | Unlock when hostile count 0 |
| Turtle rescue spam | **Risk** | Prompt + E remote + attack rescue; need debounce/`Rescued` attr strict |
| OilSlow + Hangover | **Opaque** | Both slow; OilSlow attr unused; HangoverUntil + moveSpeed min |
| Mobile + keyboard | **OK** | Dual bind |
| Exploit IFrame attr | **Mitigated** | Server table; VFX attr only |
| PendingDamage races | **Open** | 0.05s poll, 0.2s window; multi-hit overwrite attr |
| SyncSettings bad key | **OK** | Whitelist |
| Smash BeachBurnout | **OK** | Rejected |
| Draft PickDraftItem unknown id | **OK** | Rejected |
| PickDraftItem over max slots | **Open** | No `itemSlots` check |
| RequestJump | **Dead** | N/A |
| Soft Z fight | **Open** | HazardService CFrame stomp |

### K. Rojo / production overlooks
- `default.project.json`: no StreamingEnabled, no StarterGui reset flags, Remotes empty folder + runtime fill.
- `rokit.toml` pins Rojo; CI = `scripts/check_invariants.sh` only.
- SpawnLocation at x=8 vs Constants.SPAWN_X=18.
- No `.github/workflows`.

---

## Comment hygiene (this commit)

Stripped narrative/section/Phase banners from Phase 0–6 hot paths. Kept `--!strict` and type exports. Kept one AudioDirector dialogue-policy guard comment.

**Files touched:** CombatService, GameService, EnemyService, HazardService, MetaService, WorldBuilder, MovementController, InputController, HUD (+ Tagline / AudioDirector for dialogue policy).

---

## Honesty vs AUDIT_FINAL grades

AUDIT_FINAL was optimistic on architecture (**C+**) and audio (**B−**). Gen-2 ruthless view: architecture still **C** (god-object), audio policy now intentionally **combat-SFX + ambience beds** with **zero dialogue audio** — grade as product choice, not “music shipped.”

---

## Top defects to burn next (see PLAN_NEXT)

1. Split GameService (Hub / Run / Draft / CombatFacade)  
2. Kill dead remotes; wire or remove EquipWeapon  
3. Fill Types.lua; delete lying item copy  
4. PendingDamage → server callback bus  
5. OilSlow read path + stack rules  
6. Draft slot validation + attack VFX suppress when UI open  
7. Settings panel (mute buses, text speed) under combat-SFX policy  
8. Turtle rescue debounce  
9. Ranged pierce cap  
10. Real Mesh/anim only after layer split stable  
