# Profile and progression implementation

Implementation work for audit findings F05–11 and F16–18, following W2 and the domain portion of W5 in `PLAN_2026_09_04_IMPROVEMENTS.md`. This record describes source changes and distinguishes deterministic validation from Roblox runtime acceptance. No production provider calls or publishing were performed during implementation.

## Stage 1: profile rules and storage boundary

`ProfileRules` is a pure schema/migration module. `ProfileAdapter` receives read, legacy-read, update, and clock functions. It does not access players, presentation, attributes, or reward logic. `MetaService` owns live player profiles and composes the actual Roblox DataStore adapter.

The existing primary store remains `FloridaMan_Meta_v2`, with schema 3 records and `u_<UserId>` keys. Existing version 1/2 records are migrated only after a successful primary read. A successful primary nil permits reading the legacy v1 store; failure of either required read quarantines the session. Future schema versions and malformed records cannot become writable defaults. Known fields are normalized against current catalogs; unknown IDs/fields are deliberately omitted. Retired audio settings are not retained. Finite/ranged numbers, unique known ownership IDs, two distinct selected personas, and owned selected weapons are enforced.

Persistent fields are deaths, Sunburn, persona ownership, persona rarity, selected persona slots, weapon ownership, selected weapon, best stage, lifetime rescued turtles, and visual settings. Weapon unlocks and selection survive death, a new run, and rejoin. Items and their evolving capacity belong to the run. Current-stage and run turtle counts remain separate from the lifetime profile field.

**Stage audit:** primary-read failure never reaches legacy fallback or an update; incompatible schemas do not claim a lease. Acquisition uses the current value inside `UpdateAsync`, so a stale preliminary read cannot overwrite a newer profile. Configuration does not interpret higher currency as newer data. No competing memory cache remains.

## Stage 2: lease, immutable saves, and shutdown

Each loaded writable profile has a unique session owner and a 180-second lease. Claim and write transforms reject another live owner. Saves also compare the expected cloud revision; an old writer cannot restore spent currency. Current provider time is evaluated inside update callbacks. Writes and lease releases use the same ownership/revision check. An immutable write token plus matching revision/content recognizes a provider commit whose response was lost; retrying that write or final release does not create a false conflict or duplicate a mutation.

All ordinary mutation and save-request functions are non-yielding. `ProfileQueue` keeps one pending flag and the latest revision per admitted player. A write takes a deep, frozen snapshot. Success advances `savedRevision` only to the revision actually written; a mutation or closing request received while the provider yielded schedules another write. Settings no-ops do not increment revisions or request writes. Settings ingress has a small token bucket. Writes have a minimum six-second gap, bounded retry backoff, a 30-second autosave/lease renewal cadence, and at most two provider workers.

A failed provider response can follow a committed update. The adapter attaches an operation token and recognizes the same immutable write on retry, including a final lease release. The queue retains the exact snapshot, expected revision, and release flag across retryable failures; newer mutations wait until that operation is acknowledged. It then writes the newest accepted revision. This avoids treating a lost response plus a later mutation as a conflicting external writer.

`GameService` owns removal ordering: call `MetaService.Unload` before clearing run state. Unload synchronously captures the final accepted run fields, then leaves the record owned by the save worker for a bounded final flush/release. `BindToClose` coordinates a 20-second flush window, with a short scheduling margin. A deadline failure is warned; a failed write is never reported as saved. Rejected/failed-load sessions can play a clearly identified temporary run but cannot spend or smash persistent progression. Profile status is exposed structurally and through a status observer; ordinary profile data is returned as copies.

**Stage audit:** deterministic tests inject a mutation and close while an earlier immutable snapshot is in flight, then a failed final write and retry. They verify the accepted newer currency/tier snapshot remains pending and is eventually released atomically. A lease timeout or revision conflict disables further writes. The scheduler has no per-request event queue or departed-player cache.

## Stage 3: hub transactions and deliberate loadout

`ItemGrantRules.HubTransaction` validates phase, hub generation, known and owned persona, slot bounds, duplicate selection, tier limits, affordability, and smash policy before returning one patch. The runtime adapter applies the patch, captures all persistent fields, requests a save, and publishes one result. Equipped personas and the starter cannot be smashed. Clearing slot 2 is explicit; the final equipped persona cannot be removed. Any unlocked persona can be selected deliberately, and an unlock does not auto-equip it.

Client commands are tables containing `personaId`, optional `slot`, `generation`, `requestId`, and a positive monotonically increasing `sequence` shared by the three shop/loadout commands. A bounded 64-result journal replays retry results without reapplying a spend. Its sequence high-water mark rejects old commands even after cache eviction. Requests from an earlier hub generation are rejected. Clients retain the same payload when retrying and use a new sequence/ID for a deliberate new action.

`HubService.GetShopState` returns the authoritative catalog array with current ownership, selected slots, tier, upgrade cost, refund, and eligibility. `GetCommandSequence` supports snapshot recovery. `StartRun` retains selected persistent fields, client/character readiness, and offer sequence while constructing a fresh run ledger/inventory.

**Stage audit:** rule tests cover affordability, atomic decisions, duplicate slot assignment, last-slot removal, equipped/starter smash refusal, valid unequip then smash, active-stage and stale-generation rejection, retry replay, and rejection after journal eviction.

## Stage 4: offers, replacement, and reachable builds

Each pending draft retains an exact server-owned allowed-ID set, offer ID, and generation. `PickDraftItem` accepts one table: `{offerId, generation, itemId, replaceIndex?}` or `{offerId, generation, skip=true}`. An offer is consumed before its non-yielding grant/advance path. Duplicate resolution is acknowledged without granting or advancing again. Rejected choices leave the offer available. `GetOffer`/`ResendOffer` recover the current UI after client readiness or rejection.

`ShowDraft` and the snapshot offer carry `offerId`, `generation`, `picks`, display records for owned `items`, `itemSlots`, and `full`. Capacity is three at the start, then four/five/six at stages 6/11/16. Death does not increase capacity. Full inventories require deliberate replacement or skip; later reward choices remain meaningful.

The centralized grant rule returns a new item array and validates catalog membership, unique ownership, capacity, and replacement bounds. The root integration owns stat recomputation before pickup healing and resulting publication. Offers exclude already-owned items. Inventory uniqueness is intentional: one copy of each item per run.

The original catalog contained only two LUCKY items. TurtleSnack, which already grants luck, now belongs to LUCKY, giving it three distinct members while preserving five HEROIC members. Pure tests construct every inscription using three distinct legal grants and validate that every weapon has a starter or stage reward route, including FinaleRocket. The shared `ProgressionCatalog` and the parent stage-completion ledger own weapon rewards; this workstream does not duplicate their table.

Descriptions now match implemented behavior: dodge bonuses reduce cooldown, SeashellShield does not promise knock resistance, generic damage-reduction items do not claim enemy-specific armor, TurtlePaladin promises healing/absorption rather than a counterattack, CrabKing does not promise a stun, cart dash promises one hit per enemy, LizardBreath specifies its Oil Gator bonus, and the Fireworks unlock hint names the finale. HEROIC healing is stated as 6% of actual damage dealt.

**Stage audit:** deterministic tests cover unoffered known items, stale generations, consumed offers, skip, invalid/NaN replacement indices, duplicate items, unchanged source arrays, all inscription sets, and all weapon unlock mappings. The root's stage completion path grants the finale through the same idempotent reward transaction.

## Validation and remaining engine acceptance

Added `tests/profiles.test.luau` and `tests/inventory.test.luau`. The coordinating task reported the initial seven-test suite passing in `artifacts/validation-01`, with no type errors in this workstream's owned files. Later ambiguous-response tests and protocol/catalog refinements require the next consolidated validation. The coordinating task runs the pinned Luau tools sequentially because available RAM is limited. Test source alone is not a passing result.

The following require the controlled Roblox test universe and were not executed by this workstream: actual DataStore retries/throttling, overlapping server lease acquisition, server shutdown timing, a fresh-process rejoin with currency and purchased tier, slow startup/removal during provider calls, UI retry behavior on keyboard/controller/touch, full-inventory replacement and stat/heal projection, final reward use after a new run, and death/rejoin persistence. Do not close the runtime release gates from compilation, fake-provider tests, or packaging alone.

## Independent integration review

Read-only review covered the complete current `GameService`, `RunContext`, `SessionService`, `StageFlowService`, `CombatFacade`, `RunStats`, `CharacterStatePublisher`, `AnalyticsAdapter`, and `FunnelService` modules. Combat internals, world geometry, and client rendering were assigned to other workstreams and are not claimed as fully reviewed here.

The coordinator fixed the concrete integration issues found: explicit combat facing now reaches the service; rejected joins clear readiness/rate caches; interaction requires a live ready Humanoid; death and character replacement update readiness; hub entry clears run movement statuses. The central `RunContext.UnlockPersona` gate now rejects FireworksEnthusiast until the authoritative finale transaction sets `completionCommitted`, covering both generic boss drops and turtle-first callbacks. The pure progression suite includes the entitlement predicate. Generation-scoped callbacks, solo admission, provider teardown ordering, and item-stat recomputation before pickup healing were traced without an additional unresolved source defect in this review.

Self-review also found and corrected the retained-snapshot retry issue described above. The combined queue/adapter regression injects a committed write with a lost response, accepts a newer currency mutation and close request, retries the original operation, then flushes/releases the newest revision. This is deterministic coverage of the integration boundary; it does not substitute for Roblox provider acceptance.
