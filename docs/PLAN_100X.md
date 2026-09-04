# Florida Man — 100× Improvement Plan

**Date:** 2026-09-04 (America/New_York)  
**Based on audit of HEAD:** `8e260c8` — see [`docs/AUDIT_FULL.md`](AUDIT_FULL.md)  
**Constraint:** Audit + plan only in that commit; **do not implement here**.

---

## What “100×” honestly means on Roblox

**100× is not** rewriting the Lua into a different engine, nor pretending SmoothPlastic Parts will look like Unreal.

**100× on Roblox = multiplicative gains across the stack that players actually feel:**

| Multiplier | From | To |
|------------|------|----|
| Art | Procedural Parts | Authored MeshParts + SurfaceAppearance + LODs |
| Body | Default R15 + number personas | Custom characters / layered clothing kits + AnimationController clips per persona |
| Juice | Neon Part VFX | VFX kit (meshes, beams, trails, impact frames) + **real audio** |
| Combat | Unowned mash + stat catalogs | Owned hitbox service + weapon behaviors + Skul-like swap mastery |
| World | Décor hallway | Set-piece *gameplay* (gates, arenas, scripted beats) |
| Production | God-object, no tests | Modular services + CI regression + DataStore meta |
| Publish | Private Rojo repo | Thumbnails, maturity, performance budgets, soft launch |

**Ceiling note:** Pure procedural Parts tops out around “charming jam game.” Crossing into commercial Roblox indie **requires custom assets + animation + audio + design depth**. This plan assumes that investment starting Phase 2.

**Ordering rule:** Never buy MeshParts before Phase 0 playability lock. Never expand catalog before weapons/skills behave differently.

---

## Phase 0 — Playability lock  
**Goal:** Facing, prompts, spawn, Cold One, Steve, silent-failure paths cannot regress.  
**Effort:** **M** (1–2 weeks calendar with 1 engineer)  
**Dependencies:** None  
**Risks:** False confidence without Studio automated smoke; attribute security half-measures.

### Concrete tasks
1. Extract **PlayabilityInvariants.md** checklist from prior P0 AUDIT (lookAlong facing, SPAWN_X=18, ClickablePrompt, Cold One walkover, Steve panel).
2. Add **server-authoritative i-frames** (server table keyed by UserId; stop trusting `IFrame` attribute for damage immunity).
3. Fix **DoAttack** hit predicate precedence (`GameService.lua` ~658) — facing-required except explicit behind-hit weapons.
4. Wire **CombatService** (or replace): move `InLaneMelee` / knockback helpers into the real attack path; delete dead code or own it.
5. Add **server attack recovery gate** matching client buffer intent.
6. **Audio smoke:** assign temporary Roblox library SoundIds to StageSounds so PlaySound is audible (placeholder pack OK).
7. **Rojo smoke script** + manual Studio checklist; optional Luau AST tests for invariant string presence (SPAWN_X, lookAlong, ClickablePrompt).
8. Mobile: temporary **on-screen Attack/Skill/Dodge/Interact** buttons (ugly OK).

### Acceptance criteria
- [ ] New player on keyboard: hub → E/prompt start → Cold One walkover → first crab kill without confusion in ≤60s  
- [ ] New player on touch: can attack/dodge without keyboard  
- [ ] Exploit attempt setting IFrame attr does **not** block server damage  
- [ ] Facing unit test / checklist documented; moonwalk cannot return unnoticed  
- [ ] At least swing/hit/UI click make sound  

### Risks
- Patching IFrame without rewriting enemy damage bridge leaves PendingDamage races.

---

## Phase 1 — Vertical slice excellence (first 3 stages = AAA-Roblox indie feel)  
**Goal:** Hub + Daytona Hangover Beach + Boardwalk Chaos + Gas Station feel like a trailer.  
**Effort:** **L**  
**Dependencies:** Phase 0  
**Risks:** Over-scoping all 20 stages; resist — only stages 0–3.

### Concrete tasks
1. **Tutorial beat map (60s):** move → jump → attack → dodge telegraph → Cold One → miniboss intro toast with camera push.
2. Rewrite stage 1–3 enemy telegraphs + spacing for teaching (already partially capped; tune timings).
3. **One hero art pass** without full pipeline: upgrade Crab King + Hotdog Cart + Slushie with best-possible Part kits *or* first MeshPart imports if Phase 2 early-starts.
4. Camera: framing volumes for MidGate open + miniboss spawn (temporary Scriptable cuts ≤0.4s).
5. HUD: icon slots (even flat colored shapes) for personas/items; kill walls of text.
6. Newspaper + draft: entrance animation, input lock clarity, gamepad focus.
7. Remove SafetyFloor from slice *or* convert fall into soft respawn at last checkpoint with juice (stakes).
8. Act 1 Steve: 3 voiced-or-typed beats tied to events (not random rotate only).

### Acceptance criteria
- [ ] External playtester completes stages 1–3 without developer coaching  
- [ ] Trailer clip of stage 1–2 looks intentional (lighting + VFX + audio + readable telegraphs)  
- [ ] “I know what to do in 60s” ≥80% in 5-person hallway test  

---

## Phase 2 — Art pipeline (meshes / animations / VFX kit)  
**Goal:** Sustainable content pipeline; stop authoring characters as Part soup.  
**Effort:** **XL**  
**Dependencies:** Phase 1 scope freeze for hero cast  
**Risks:** Pipeline stall; scope explosion; MeshPart over-budget on low-end devices.

### Concrete tasks
1. Choose tool chain: Blender → FBX → Roblox importer; document in `docs/ART_PIPELINE.md`.
2. **Hero mesh set v1:** Florida Man body kit (or heavily customized R15), Captain Steve, Beach Crab, Crab King, Drive-Thru Gator, Spillfather blockout.
3. **SurfaceAppearance** materials: sand, sludge, hazmat, neon gas.
4. **Animation set:** idle/run/jump/dodge/attack1–3/skill/swap per persona (start with BeachBurnout + CrabKing).
5. **VFX kit module:** replace ad-hoc Parts with reusable emitters + mesh flashes; weapon-specific swing arcs.
6. UI image pack: icons for 8 personas, rarity frames, newspaper masthead, draft cards.
7. Thumbnail / icon / loading screen.
8. LOD + part-count budget sheet per stage.

### Acceptance criteria
- [ ] ≥6 gameplay characters use MeshParts in-slice  
- [ ] Attack animations play for starter persona  
- [ ] Marketplace-quality icon set exists in repo (or asset IDs doc)  
- [ ] Perf budget: mid-range Android target frame time documented and measured on slice  

---

## Phase 3 — Combat depth (Skul-like swap mastery)  
**Goal:** Personas + weapons + swap create decisions every 2–3 seconds.  
**Effort:** **XL**  
**Dependencies:** Phase 0 combat ownership; Phase 2 anims strongly preferred  
**Risks:** Feature bloat; mushy damage inflation.

### Concrete tasks
1. Create **`CombatService` real owner:** hitboxes, recovery, cancel windows, team filters, knockback impulses.
2. **Weapon behaviors:** melee / ranged / thrown actually differ (projectile lane entities, arc, charge).
3. Map **persona attack movesets** (3-hit unique timings) separate from weapons (weapons modify moveset).
4. **Swap cancel** rules: swap-attack as combo route with risk/reward; meter or cooldown readability on HUD.
5. Skills: distinct gameplay (Turtle shield grants reflect; Snake summon persists; Cart dash has armor frames) — not only VFX skins.
6. Implement missing item specials (lifesteal, paperCut, radio, sunburnFind) or **delete lies from copy**.
7. Enemy hurtboxes + hyper armor on bosses during phase shifts.
8. Damage numbers / hitflash / freeze frames calibrated; audio layers (light/medium/heavy).
9. Anti-cheat: server rewind-lite validation (range, facing, CD, rate limits).

### Acceptance criteria
- [ ] Blind playtester can explain difference between 3 weapons after using each once  
- [ ] Swap is used intentionally in boss practice (≥1 swap/10s average among skilled players)  
- [ ] Catalog claims match code (no dead specials)  
- [ ] Exploit smoke: speedhack remotes rate-limited; IFrame not client-authoritative  

---

## Phase 4 — World & story production  
**Goal:** Stages become places; story becomes staged.  
**Effort:** **XL**  
**Dependencies:** Phase 1 slice patterns; Phase 2 props  
**Risks:** 20-stage burnout — batch acts.

### Concrete tasks
1. Per-act **set-piece gameplay verbs** (not décor): e.g. Boardwalk fryer forces jump rhythm; Canal requires pad chains; Lab conveyor moving hazards; Barge real gaps with checkpoints.
2. MidGate → **room system** (enter arena, wave clear, door unlock with fanfare).
3. Boss arenas with phase changes that alter geometry (Spillfather slick ring expands walkable safe zones).
4. Story: 8–12 **comic/newspaper interstitial** art panels; Steve vignettes; turtle rescue setpiece.
5. Remove or redesign SafetyFloor globally; deaths/falls meaningful but fair.
6. Ambient particles + biome audio beds.
7. Optional branching: “rescue first” vs “push gate” at Act 3 (even soft branch).

### Acceptance criteria
- [ ] Each act has ≥1 unforgettable set-piece players mention unprompted  
- [ ] Spillfather phase 2/3 change player positioning strategy  
- [ ] Story comprehension test: players can summarize GulfGulp plot after Act 2  

---

## Phase 5 — Full campaign polish + audio  
**Goal:** Acts 1–5 complete at slice quality; audio is a character.  
**Effort:** **XL**  
**Dependencies:** Phases 2–4  
**Risks:** Audio licensing; music loops fatigue.

### Concrete tasks
1. Audio director pass: SFX library, music per biome, boss themes, UI stingers, mix bus (Master/SFX/Music/UI/Ambience SoundGroups + ducking).
2. VO optional: Steve one-liners (short) or text-with-typewriter + SFX.
3. Campaign pacing: rest hubs, shop density, miniboss HP retune.
4. Credits / sunrise sequence art + music swell.
5. Accessibility: screen shake toggle, colorblind telegraph shapes, rumble strength.
6. Bug bash week; crash/telemetry hooks.

### Acceptance criteria
- [ ] Full run audio never silent on core verbs  
- [ ] Shake-off option exists  
- [ ] Full campaign completable by external testers with ≤3 softlocks  

---

## Phase 6 — Meta, balance, publish  
**Goal:** Roguelite retention + Roblox publish readiness.  
**Effort:** **L–XL**  
**Dependencies:** Phase 5 content complete  
**Risks:** Policy rejection; economy inflation.

### Concrete tasks
1. **DataStore** meta: unlocks, sunburn, settings, stats.
2. Balance spreadsheet → `Balance.lua` generatored; nightly sim of DPS vs stage HP.
3. Daily/weekly run modifiers (light).
4. Publish pack: thumbnails, description, maturity labels, content guidelines compliance review (already mostly clean — verify).
5. Performance: StreamingEnabled strategy, enemy pooling, telegraph pooling.
6. Soft launch private servers → public; KPI dashboard (FTUE 60s, D1 return).
7. Split GameService into RunService / HubService / DraftService / HazardService / MetaService.

### Acceptance criteria
- [ ] Meta persists across sessions  
- [ ] Experience passes Roblox publish checklist internally  
- [ ] FTUE completion ≥70% in soft launch  
- [ ] GameService <400 lines; combat owned by CombatService  

---

## Prioritized backlog (52 items)

### P0 — Stop the bleeding (do before content expansion)
1. Server-authoritative i-frames (kill client attr trust)  
2. Fix DoAttack facing/`or` precedence bug  
3. Assign placeholder SoundIds; verify PlaySound path  
4. Mobile touch combat buttons  
5. Server attack rate limit / recovery  
6. Facing + spawn + prompt regression checklist automated or scripted  
7. Cold One / MidGate / Steve interaction telemetry toasts → proper FTUE flags  
8. Own or delete CombatService; extract combat from GameService  
9. Stop advertising unused weapon keys; wire EquipWeapon UI  
10. Remove Hangover attr reuse for oil slicks (separate Slow status)  
11. PendingDamage attribute bridge → secure server apply  
12. SafetyFloor decision: checkpoint respawn vs lethal with fair recovery  

### P1 — Vertical slice & systems truth
13. 60-second tutorial beat script  
14. Crab King hero art + anim blockout  
15. Weapon kind behaviors (melee/ranged/thrown)  
16. Persona movesets independent of weapons  
17. Implement or delete item specials / set bonus lies  
18. Skill gameplay distinctiveness pass (8 personas)  
19. Swap mastery tutorial + HUD tempo meter  
20. Enemy hurtbox standardization  
21. Boss phase graphs (not only HP thresholds) for Spillfather + 2 minibosses  
22. Camera event framing (door, boss intro)  
23. HUD iconography pass  
24. Draft/Newspaper motion + gamepad cursor  
25. Hazard verb clarity (damage vs slow vs wind) with VFX/SFX  
26. MidGate → arena room pattern in stages 3–5  
27. Audio bus architecture  
28. Part-count / draw budget for stages 1–3  
29. Anti-spam remote middleware  
30. Split GameService run loop vs combat  

### P2 — Production scale & publish
31. Art pipeline docs + Blender templates  
32. MeshPart hero cast (6+)  
33. Full animation set BeachBurnout/CrabKing/GatorHauler  
34. VFX kit replacement for neon Parts  
35. UI image pack + rarity frames  
36. Thumbnail/icon/loading  
37. Biome music + ambience beds  
38. Steve VO or premium typewriter scenes  
39. Act 2–5 set-piece gameplay verbs  
40. Real barge/pipe platforming without SafetyFloor cheese  
41. Turtle rescue dedicated interact + escort beat  
42. DataStore meta profile  
43. Economy sim + Balance codegen  
44. Enemy/telegraph pooling  
45. StreamingEnabled + memory soak test  
46. Soft launch KPI instrumentation  
47. Accessibility (shake, colorblind, subtitle size)  
48. Credits cinematic art  
49. Daily modifier meta  
50. Marketplace page copy + policy review  
51. CI: Selene/stylua + invariant grep + Rojo build artifact  
52. Content freeze checklist before public launch  

---

## Effort map (rough)

| Phase | Effort | Calendar (1–2 eng) | Ships player value |
|------|:------:|--------------------|--------------------|
| 0 | M | 1–2 w | Trust + FTUE baseline |
| 1 | L | 3–5 w | “This game is good” trailer |
| 2 | XL | 6–10 w | Commercial look |
| 3 | XL | 6–10 w | Skul-like mastery |
| 4 | XL | 6–10 w | Campaign places |
| 5 | XL | 4–8 w | Emotional finish |
| 6 | L–XL | 3–6 w | Retention + publish |

Parallelism: Art (2) can overlap late Phase 1; Audio bed can start anytime after Phase 0 placeholders.

---

## Dependency graph (simplified)

```
Phase0 ──► Phase1 ──► Phase4 ──► Phase5 ──► Phase6
              │                      ▲
              └──► Phase2 ──► Phase3 ┘
```

---

## Explicit non-goals (for now)
- Do **not** open Roblox Studio automation on user machines from agents.  
- Do **not** expand enemy/item/weapon **counts** until behaviors are true.  
- Do **not** chase photorealism; chase **readable Florida cartoon** at MeshPart quality.  
- Do **not** implement this plan in the audit commit.

---

## Definition of done for “100×”
A stranger on mobile completes Act 1 smiling; a Skul fan says swap/combat has intent; a Roblox creator says art/audio look published; meta persists; CI protects facing/prompts; Spillfather is a story you feel in your hands — not a HP bar with wider neon rectangles.
