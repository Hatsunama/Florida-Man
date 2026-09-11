> Historical planning/reference document. Current implementation and release decisions use [IMPLEMENTATION_PROGRESS](IMPLEMENTATION_PROGRESS.md) and [RELEASE_ACCEPTANCE](RELEASE_ACCEPTANCE.md). Claims below have not been re-certified for the repaired source.

# Florida Man — PLAN_NEXT (100× from HEAD `a28a266`)

**Date:** 2026-09-04 (America/New_York)  
**Based on:** [`AUDIT_LAYERS.md`](AUDIT_LAYERS.md)  
**Prior plan (executed 0–6):** [`PLAN_100X.md`](PLAN_100X.md)  
**Constraint:** Feasible incremental phases. Do **not** open Studio from agents. Do **not** invent Mesh asset IDs.

---

## Product policies (non-negotiable going forward)

### 1. Dialogue = popup text only
- **All** Steve / story / tutorial conversations use **Tagline**, **Toast**, and/or **Newspaper** panels.
- **No dialogue VO.** No typewriter SFX. No “Steve beep” as speech substitute.
- Implemented seed (this commit): `Tagline.lua` visual typewriter only; `AudioDirector` blocks `SFX_SteveBeep` / `SFX_Typewriter`.
- **Deprecate:** AudioDirector Music/UI beds used as dialogue; Newspaper may keep a one-shot UI sting **or** go silent — prefer silent for dialogue cards, optional `SFX_UIClick` only on buttons.
- **Keep:** Combat feedback SFX (`SFX_Swing`, `SFX_Hit`, `SFX_Dodge`, enemy clicks) — policy name: **`SFX combat only (+ optional UI click)`**.
- Biome ambience beds: optional; never carry story content. Document as ambience, not score. Licensed music is a later optional layer, **not** dialogue.

### 2. Comment hygiene
- Hot paths stay comment-sparse: no Phase banners, no narrative essays, no “actually:” contradictions.
- Keep `--!strict`, exported types, and rare invariant one-liners (security/policy).
- New code: name functions so comments are unnecessary.

### 3. Layer law
| Layer | May | Must not |
|-------|-----|----------|
| shared | Data, pure fn, remote names | DataStore, spawn world, deal damage |
| server *Service | Authority, persist, spawn | Trust client attrs for immunity/damage |
| client Controllers | Prediction, VFX, input | Final damage, meta currency |
| client UI | Display + FireServer | Local economy truth, settings entitlement without server ack |

---

## North-star (what “100× from here” means)

Phases 0–6 bought playability, combat ownership, meta stub, publish checklist.  
**Next 100×** = layer-clean iteration + honest catalogs + readable stage verbs + Mesh/anim **after** the god-object dies + dialogue-as-UI discipline.

| Multiplier | From (HEAD) | To |
|------------|-------------|-----|
| Architecture | GameService 1.6k | ≤400 orchestrator + Hub/Run/Draft/Combat services |
| Catalog honesty | Lying specials / dead remotes | Every field drives behavior or is deleted |
| Dialogue | Mixed audio+text | Popup-only (Tagline/Toast/Newspaper) |
| Settings | 2 toggles | Mute buses, text speed, reduce motion |
| Edge hardness | Soft mitigations | Explicit tests in `check_invariants.sh` + Studio checklist |
| Art | Part kits | Real MeshPart pass **only after** Phase N1–N2 |

---

## Phase N0 — Hygiene lock (≤3 days)
**Goal:** Dead code / comment / dialogue policy cannot regress.  
**Effort:** S  
**Deps:** none

### Tasks
1. Remove `RequestJump` from `Remotes.NAMES` (or implement jump buffer remote — prefer remove).
2. Either wire `EquipWeapon` UI (cycle unlocked weapons) **or** remove remote + server handler.
3. Expand `Types.lua` with `RunState` mirrors, `MetaProfile`, `WeaponKind`, `HazardKind` (move exports gradually).
4. Invariants script: assert no `SFX_SteveBeep` play sites; assert Tagline has no AudioDirector require; assert `HasIFrames` still server-table.
5. Delete empty MetaService Studio block; delete empty hub Flame tick branch.
6. Draft: enforce `itemSlots`; suppress client swing VFX when `FM_Draft`/`FM_Newspaper`/`FM_Steve` open (mirror Space gate).

### Acceptance
- [ ] Grep: zero `RequestJump` usage  
- [ ] Grep: Tagline has no `AudioDirector`  
- [ ] PickDraftItem respects slots  
- [ ] `./scripts/check_invariants.sh` green + new dialogue/remote checks  

---

## Phase N1 — GameService split (1–2 weeks)
**Goal:** Architecture grade → **B−**. GameService ≤400 lines.  
**Effort:** L  
**Deps:** N0

### Extract order
1. **DraftService** — newspaper continue, draft roll (daily luck), pick item, slot rules  
2. **HubService** — StartRun, Steve talk/smash/upgrade, bonfire prompts  
3. **RunService** (name carefully vs Roblox) → **StageFlowService** — LoadStage, TickWaves, MidGate, Cold One, finish/credits  
4. **CombatFacade** — thin wrappers calling CombatService + EnemyService from remotes  
5. GameService becomes InitPlayer + wire remotes + tick pump only  

### Acceptance
- [ ] GameService line count ≤400  
- [ ] No behavior change on smoke checklist stages 1–3  
- [ ] Meta/Hazard remain sole owners of persist/hazards  

---

## Phase N2 — Trust & edge hardening (1 week)
**Goal:** Edge-case grade → **B**.  
**Effort:** M  
**Deps:** N1 helpful but can parallelize PendingDamage

### Tasks
1. Replace `PendingDamage` attrs with `EnemyService.OnPlayerHit` callback registered by CombatFacade (server memory).  
2. Turtle rescue: single path (ProximityPrompt → remote); debounce 1.5s; attack-rescue removed or gated.  
3. OilSlow: MovementController reads attr **or** delete attr and document moveSpeed-only; define stack with Hangover (min mult, not multiply twice blindly).  
4. Soft-fall: max 3 toasts/stage; snap checkpoint to last solid ground sample.  
5. DataStore: on GetAsync fail, **do not** clobber memory profile if CaptureFromRun has fresher session; surface Toast “Cloud save offline”.  
6. Double-save: MetaService owns PlayerRemoving; GameService only `CaptureFromRun` + optional Save if profile dirty flag.  
7. Remotes: rate-limit RequestAttack/Skill/Dodge per player (token bucket).  
8. MidGate: if stage has MidGate and wave table empty, never lock (0-enemy softlock already unlocked — add invariant).  

### Acceptance
- [ ] Exploit IFrame attr still useless (regression)  
- [ ] Turtle cannot grant double sunburn/count  
- [ ] Studio offline DataStore: toast once, meta survives session  

---

## Phase N3 — Catalog honesty & power fantasy (1–2 weeks)
**Goal:** False-code grade → **B**.  
**Effort:** M  
**Deps:** N0

### Tasks
1. Fix or rewrite lying copy: BonfireEmber (implement on-dodge damage buff **or** change description).  
2. GREASY/HUMID set text match code.  
3. Weapon unlock table covers every `Weapons.List` id **or** cull unused weapons from catalog.  
4. Cap ranged pierce (1–2 hits) vs thrown single.  
5. `hoaCone`: damage tick **or** remove from `hazards` arrays.  
6. Balance pass: Act 3–4 density with MaxHostiles=4 + puddles — telegraph budget.  
7. Update `BALANCE_SHEET.md` after culls.  

### Acceptance
- [ ] Every `special` string has exactly one code owner  
- [ ] Every weapon either unlocks in-run or is removed  
- [ ] No README claim of “28 weapons” if fewer behave  

---

## Phase N4 — Options / a11y / dialogue UX (1 week)
**Goal:** Options grade → **B**.  
**Effort:** M  
**Deps:** dialogue policy

### Tasks
1. Settings panel (pause or HUD drawer):  
   - Shake (exists)  
   - Colorblind tele (exists)  
   - **Master / SFX / Ambience mute** (Music stays 0 under combat-SFX policy unless licensed beds added later)  
   - **Reduce motion** (disable hitstop camera punch / land squash)  
   - **Tagline text speed** (slow/normal/instant)  
2. Persist new settings via MetaService schema v2 (`FloridaMan_Meta_v2` or migrate).  
3. Newspaper/Steve: prefer popup text; optional UI click only.  
4. Mobile: ensure settings hit targets ≥44px.  

### Acceptance
- [ ] Mute SFX → combat silent; Tagline still readable  
- [ ] Instant text speed skips typewriter loop  
- [ ] Rejoin restores settings (DataStore or memory)  

---

## Phase N5 — Level verb differences (2 weeks)
**Goal:** Levels grade → **B**.  
**Effort:** L  
**Deps:** N1 StageFlow

### Tasks
1. Each act gets **one unique verb** beyond décor:  
   - Act1: timed hazard rhythm (exists — tune)  
   - Act2: pad-only traversal (fail soft-fall if in deep water too long)  
   - Act3: rescue escort (turtle moves toward goal when near player)  
   - Act4: conveyor direction flips on timer  
   - Act5: barge gaps with wind opposing jump  
2. Consume `platformLedges` / `scalingTier` for density, not cosmetics only.  
3. MidGate camera focus already exists — add one story Tagline beat on first lock per act.  
4. No SafetyFloor regression.  

### Acceptance
- [ ] Playtester can name how Act2 “feels different” from Act1 without décor talk  
- [ ] Turtle escort stage completable without attack-rescue  

---

## Phase N6 — Combat depth pass (2 weeks)
**Goal:** Combat → **B+** feel without Mesh.  
**Effort:** L  
**Deps:** N1 CombatFacade

### Tasks
1. Move DoAttack/DoSkill/DoSwap bodies into CombatFacade; GameService remotes only.  
2. Moveset cancel windows documented in Types + HUD flash.  
3. Weapon kind secondary effects (foam vs fire enemies, net briefly roots).  
4. Swap punish window readable (color + Tagline-free Toast).  
5. Client recovery reads server `attackReadyAt` via StateUpdate (fix ghost swings).  

### Acceptance
- [ ] Lawn Dart arc and Roman Candle flat shot feel distinct in 5-person blind test  
- [ ] No client-only god swings during server recovery  

---

## Phase N7 — Art / anim pipeline execution (3–6 weeks)
**Goal:** Art → **B−** minimum.  
**Effort:** XL  
**Deps:** N1 stable; follow `ART_PIPELINE.md`

### Tasks
1. Import **real** MeshParts for: Crab, Steve, Spillfather, player weapon props (no invented asset IDs in Lua until uploaded).  
2. AnimationController clips: attack 1–3, dodge, skill per starter persona.  
3. LOD / part budgets per stage in PUBLISH_CHECKLIST.  
4. Thumbnails 512 + 1920 authored and linked in checklist.  

### Acceptance
- [ ] Trailer still of stage 1 not readable as “default R15 in Parts town”  
- [ ] Invariants: no fake `rbxassetid://000` placeholders  

---

## Phase N8 — Soft launch & telemetry (1–2 weeks)
**Goal:** Production → **B−**.  
**Effort:** M  
**Deps:** N2, N4, publish pack

### Tasks
1. Friends-only publish; enable API Services; verify Meta rejoin.  
2. Lightweight funnel markers (TutorialBeat already): hub_start, cold_one, stage3_clear, death.  
3. KPI: FTUE 60s clear rate; D1 return.  
4. Crash/softlock watch on MidGate + draft.  

### Acceptance
- [ ] External player clears 1–3 in ≤15 min uncoached  
- [ ] DataStore confirmed on published place  

---

## Phase map (summary)

| Phase | Name | Effort | Primary outcome |
|------:|------|:------:|-----------------|
| **N0** | Hygiene lock | S | Dead remotes, dialogue policy locked, draft slots |
| **N1** | GameService split | L | ≤400 line orchestrator; layer law enforceable |
| **N2** | Trust & edges | M | PendingDamage gone; turtle/OilSlow/DataStore hardened |
| **N3** | Catalog honesty | M | No lying specials; pierce caps; unlocks real |
| **N4** | Options / dialogue UX | M | Mute + text speed; popup-only confirmed |
| **N5** | Level verbs | L | Per-act gameplay difference |
| **N6** | Combat depth | L | Facade + weapon verbs + recovery sync |
| **N7** | Art / anim | XL | Real meshes + clips |
| **N8** | Soft launch | M | Live meta + KPIs |

**Feasible calendar (1 engineer):** ~10–16 weeks to N8 without N7 meshes; +3–6 weeks with art.

---

## Explicit non-goals (until listed phase)

- Opening Studio from CI agents  
- Inventing Mesh/Sound asset IDs  
- Dialogue VO / music-as-speech  
- Expanding enemy catalog before N3 honesty  
- Full networking multiplayer co-op  

---

## Regression anchors (never break)

From `PlayabilityInvariants.md` + Gen-2:
1. `CFrame.lookAlong` facing; AlignOrientation rigid; AlignPosition Z-only  
2. `SPAWN_X = 18`; ClickablePrompt on Flame/Steve  
3. Server `HasIFrames` table — never trust client immunity attr  
4. Cold One walkover  
5. **Dialogue = Tagline/Toast/Newspaper only** (no dialogue SFX)  
6. Comment-sparse hot paths  

---

## First week checklist (start here)

1. N0 remotes cull + draft slots + swing suppress in UI  
2. N0 invariants for dialogue policy  
3. N1 DraftService extract (smallest slice)  
4. N2 PendingDamage callback spike  
5. N3 BonfireEmber honesty (one-line fix)  

When those land, re-grade with a short `docs/AUDIT_LAYERS_DELTA.md` rather than rewriting this plan.
