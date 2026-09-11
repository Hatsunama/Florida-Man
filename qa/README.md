# Isolated Studio audit helpers

The separately generated QA place contains a server-only StudioAudit module/StudioAuditBridge script and a StudioClientAudit LocalScript. All are absent from default.project.json. The server bridge registers StudioAuditCommand in ServerScriptService; the client helper registers StudioClientAuditCommand in the live PlayerScripts. Both are local BindableFunction endpoints in their respective execution contexts, not network RemoteEvents/RemoteFunctions. Registration does not run a test, publish or change provider/experience settings.

Use the [consolidated re-audit ledger](../docs/REAUDIT_2026_09_05.md) and [structured runtime record](../docs/reaudit-evidence-2026-09-05/runtime-results.json) for package identities, actual results and unexecuted checks. The latest [main09 report](../artifacts/reaudit-build-09/report.json) passed 112 checks across 78 runtime files and 15 behavioral suites. [QA09](../artifacts/reaudit-studio-09/report.json) passed six isolated compile/sourcemap/type/package checks with sourceStable=true and the default project unchanged. **Neither 09 artifact has engine acceptance.** The observed runtime actions below belong to 08 or earlier, as labelled; they do not establish the new dialogue repair.

The latest QA09 main BuildIdentity is `d5e040a6ef1427f3b5250a56d8d22d51180cadc15cdf69b42e4fdc8fb2b5a8e9`; QA package SHA is `c538c7aaacc4b40abaf951022ef3a358ec4a8294ed4df33b5cfd533580165a3e`. Its baseline is artifacts/reaudit-build-09/report.json, report SHA `1018927768bdc234e186c2db3c4a2d4863f32abe1c499fe9e125605045a239ba`; main package SHA `573103ba2f1c7adec312b738034a146b5ab45f47d5b677fa9a091f242e7a93fa`. Its engineAcceptance=not-executed is current. Historical QA08 shared main identity 3343bd4af705… and QA package SHA `86b3e72fb44bb28e720e3817f08bea2bd42fc0706b5ad744bcc1c562b2fb5bee`; that is the package with the scoped runtime observations below.

## Build a matching isolated place

Run the ordinary validator first, then derive the QA place from that exact passing report. These are example output names for a new run, not existing success claims:

```powershell
python scripts/validate.py --tools-dir "$env:TEMP/florida-man-audit-tools-20260904" --output artifacts/qa-baseline
python scripts/build_studio_audit.py --tools-dir "$env:TEMP/florida-man-audit-tools-20260904" --validation-report artifacts/qa-baseline/report.json --output artifacts/qa-session
```

The builder checks the baseline source/test/project hashes and shared validation lock, compiles the server helper/bridge and client helper, generates a derived project/sourcemap, checks Roblox types and packages the QA place sequentially. It records the baseline report hash, separate helper/bridge/client hashes, main BuildIdentity and final package hash. It rejects using the baseline directory as QA output and rejects preexisting client QA mapping in the default project. A failed run must have a failed report even if an older package remains. The default project stays unchanged; regenerate after moving the repository because the derived project uses absolute paths. Neither command launches Studio.

Respect the host [resource policy](../docs/RELEASE_ACCEPTANCE.md): one Studio instance, serial heavy tools and no changes to unrelated processes or paging/security settings.

## Invoke the existing server bridge

Start a server play session in the generated local place and keep game.PlaceId equal to 0. Use the **server** Command Bar, addressing the bridge already registered by the running server script.

The audit's direct Command Bar require attempt returned a session-owner guard refusal in this environment. Invoking the existing server BindableFunction succeeded. Do not weaken guards or create a second session owner to work around that refusal; use the bridge execution context.

A read-only example:

```luau
local bridge = game:GetService("ServerScriptService"):WaitForChild("StudioAuditCommand")
local result = bridge:Invoke("Snapshot")
print(game:GetService("HttpService"):JSONEncode(result))
```

Run one requested diagnostic at a time. Check its actual returned ok/reason, availability and truncation fields. Mutating commands can relocate/reset the local test run; they are not a way to demonstrate ordinary traversal.

| Allowlisted command | Argument | Effect and limits |
|---|---|---|
| ListStages | none | Sorted stage IDs/index/names, including Hub; does not load them |
| ResetToStage | known stage ID string, at most 80 characters | Normal Hub→StartRun→target transition, resetting run items/reward ledgers/counters and preserving persistent loadout |
| NearCaptainSteve | none | Guarded relocation beside Steve in the hub; the tester must then press E normally |
| Snapshot | none | Bounded copy of latest server RuntimeMetrics sample; may be unavailable for the first five seconds |
| ScanAudio | none through bridge | Read-only scan with an 8,000-instance limit; reports up to 32 findings and truncation |
| BeginTrace | none | Arms a bounded 30-second server position/command-receipt trace for the current character |
| Trace | none | Returns the captured trace or a no-trace reason; does not start recording |
| RunStageSmoke | none | Explicit test relocations/lethal damage exercise real stage/wave/rescue/reward service paths |
| RunLifecycleSmoke | none | Three guarded local death/recovery cycles, including a Humanoid reset and duplicate-death callback check |

Unknown command names are rejected. The bridge rejects concurrent invocation while busy and converts an exception into a bounded failure reason.

Every mutating **server** helper requires server Studio execution, PlaceId 0, the currently admitted solo session owner, a loaded profile with writable=false, and a ready living character. A loading/writable profile, absent owner or unready/dead character causes refusal. The helper does not enable API access, grant every loadout, alter provider settings or save test progress. Client diagnostic guards and scope are described separately below; client input continues through normal server authorization.

## Test NPC input separately from relocation

Return to the hub, then invoke:

```luau
local bridge = game:GetService("ServerScriptService"):WaitForChild("StudioAuditCommand")
print(game:GetService("HttpService"):JSONEncode(bridge:Invoke("NearCaptainSteve")))
```

After an ok result, return focus to the game and press E yourself. Inspect the native prompt, shop opening, Close and subsequent small conversation popup. Relocation establishes proximity; it does not test walking there or choose the NPC action automatically.

This relocation sequence succeeded in the root's main 05-source QA session: native E opened Steve's shop, and Close revealed a small Captain Steve popup; see the [05 NPC capture](../docs/reaudit-evidence-2026-09-05/build05-npc-e-opened.png). In matching QA08, real Input.Intent walking/jump reached Steve and native E opened the shop without any location teleport in that session; see the [08 walk/E capture](../docs/reaudit-evidence-2026-09-05/build08-walk-npc-e.png). The latter removes relocation from that approach case, but still does not verify native held movement keys, controller/touch, or complete dialogue reading.

## Trace movement without inventing acceptance

Invoke BeginTrace, return to the game, perform one controlled movement/jump/dodge experiment within 30 seconds, then invoke Trace in a separate Command Bar submission:

```luau
local bridge = game:GetService("ServerScriptService"):WaitForChild("StudioAuditCommand")
print(game:GetService("HttpService"):JSONEncode(bridge:Invoke("BeginTrace")))
```

```luau
local bridge = game:GetService("ServerScriptService"):WaitForChild("StudioAuditCommand")
print(game:GetService("HttpService"):JSONEncode(bridge:Invoke("Trace")))
```

The trace stores sample count, elapsed time, starting/current/minimum/maximum X, starting/current/maximum Y, reset-revision change and received attack/skill/swap/dodge command counts. It disconnects after 30 seconds, character replacement or missing root; starting a trace disconnects the previous recorder. Command counts show receipt, not accepted damage or action success. Combine position results with readiness/phase, accepted events and the relevant test result. This does not measure client FPS, input latency or live persistence.

The [main 05 engine-events excerpt](../docs/reaudit-evidence-2026-09-05/build05-engine-events.txt) contains an actual native Space test: 1,794 samples over 29.994905 seconds, Y 4.176333427429199 → apex 11.499826431274414 → 4.176333427429199. The rise is 7.323493003845215 studs, resets=0 and commands=[] for the watched combat remotes. X remained essentially unchanged. This establishes that jump/return case; it does not establish walking, short-hop comparisons, all rigs/devices or new-build behavior.

## Invoke client diagnostics in the client context

After a matching QA package containing StudioClientAudit passes its checks, use the **client** Command Bar for this endpoint. ServerScriptService.StudioAuditCommand and LocalPlayer.PlayerScripts.StudioClientAuditCommand are different endpoints with different allowlists. Do not require live gameplay modules directly from Command Bar or invoke the client endpoint from the server.

```luau
local player = game:GetService("Players").LocalPlayer
local command = player:WaitForChild("PlayerScripts"):WaitForChild("StudioClientAuditCommand")
local result = command:Invoke("Read")
print(game:GetService("HttpService"):JSONEncode(result))
```

| Client command | What it does | Evidence limits |
|---|---|---|
| Read | Bounded local character, accepted-state/input-readiness and visible-text candidate snapshot; up to 2,000 GUI nodes, 32 screen records and 60 text records, with omissions reported | Text candidates/rectangles do not prove clipping, visual occlusion, readability or usability |
| ScanAudio | Read-only client instance scan up to 8,000 nodes; counts Sound/AudioPlayer sources, playing/nonzero-volume state and other Audio-class objects; up to 32 source records plus omission/truncation fields | Does not certify voice configuration or absence of past/future audio; inspect the full reported scope |
| MovementSmoke | Bounded real Input.Intent sequence: rightward movement/release, jump/release/landing, then available attack/skill/dodge intents; observes command results and combat events | Does not send native keyboard/touch/controller input, teleport, patch state or directly grant rewards; no campaign or difficulty proof |

The client endpoint requires Studio/client/PlaceId 0, registers once under live PlayerScripts and rejects unknown/concurrent commands. MovementSmoke additionally requires a ready living Hub/Active character and available movement/jump, checks the same character/stage/generation throughout, stops on death/unavailability, and uses a nine-second deadline with a held-input release watchdog. Connections/input are cleaned up at exit. The normal server still decides whether combat commands are authorized; the client helper supplies no server capability.

Invoke ScanAudio or MovementSmoke with the same client example by changing the command name. Do not provide manual input concurrently with MovementSmoke: server events are associated by action type/time, not a QA request ID, so manual events can be indistinguishable. Examine completed, movement.deltaX, jump.rise/landed, motionResetStable, each action's availability/submission/acceptance/rejection and allActionsAccepted. An overall ok can coexist with unavailable combat actions in the hub; it is not proof those actions ran. Event arrays are bounded and report dropped records.

QA08 actually invoked all three client commands. ScanAudio inspected 2,342 nodes with zero Sound/AudioPlayer sources, no other Audio-class objects, playing=0, nonzeroVolume=0 and truncated=false. MovementSmoke completed in 1.53 seconds: rightward deltaX 6.610567092895508, jump rise 6.362632513046265, landed=true and motionResetStable=true. Attack/skill/dodge were unavailable in Hub: every record says unavailable-no-intent, intentSubmitted=false and acceptanceObserved=false; allActionsAccepted=false is expected for that scope and proves no combat success.

Read exposed a real UI defect: the current popup body was only “retry.” although its content width was 376px. The log is truncated after preserved fields; do not infer missing fields. Source tracing found early zero-viewport pagination permanently fragmented accepted messages. Main09's repair stores complete messages and Notes entries, waits for valid viewport/actual text dimensions, and reflows using grapheme byte offsets without consuming text until advance. Its production pagination suite passed. Complete-conversation engine reading remains unexecuted. [Durable08 events](../docs/reaudit-evidence-2026-09-05/build08-engine-events.txt) and the structured record preserve the original failure and result limits.

## Stage and lifecycle smoke

RunStageSmoke creates a fresh run for each of 20 stages, checks readiness and a stage-owned support ray, explicitly triggers real waves/rooms, kills test hostiles, rescues through real services, checks reward/summary state and repeats completion before restoring the hub. The QA08 helper emits compact QA_STAGE records so individual failures can be preserved; its stage smoke was not run in that session.

Avoid logging only one enormous JSON value. Keep the overall result, every per-stage record, restoration result and any truncation/error. For example:

```luau
local bridge = game:GetService("ServerScriptService"):WaitForChild("StudioAuditCommand")
local result = bridge:Invoke("RunStageSmoke")
print("QA_SUMMARY", result.ok, result.restored, result.reason)
for _, stage in result.stages or {} do
    print("QA_RESULT", game:GetService("HttpService"):JSONEncode(stage))
end
```

The first executed QA06 smoke returned 20 case records but failed a spawn world-support assertion, and the aggregate JSON log was truncated. **No all-stage progression pass is established.** The assertion requires the first collidable ray hit to belong to GameWorld. Persistent collidable FM_Spawn and an 80-stud FM_SafetyPad outside that world can explain an ownership assertion without proving absent physical support. Main 08 makes FM_Spawn invisible/noncollidable and retires FM_SafetyPad after world construction. QA08's stage/lifecycle/Active-combat tests were **not executed**: commit headroom was 1.45–1.61 GiB, below the 2 GiB operating threshold. Do not label the earlier result either a missing-floor playability failure or a campaign pass.

RunLifecycleSmoke uses real combat damage in two cycles and Humanoid.Health=0 in one, waits for one actual death count, tests a repeated death callback and checks bounded return/replacement readiness. It does not test storage/rejoin or long-run resource stability. No lifecycle success is claimed until its actual result is recorded.

Even successful smoke execution only checks the exercised service composition. Test relocations and lethal damage do not establish player traversal, jump mechanics, combat balance, input usability or a continuous twenty-stage campaign.

## Audio, metrics and current evidence limits

Snapshot returns a copy bounded by depth, entry count and string length. It reports existing server measurements, not client frame time. ScanAudio examines server-visible Sound/Audio-class instances and reports its coverage/truncation. The bridge uses 8,000 nodes; the underlying helper supports 100–20,000 and at most 32 findings.

The main 05-source session scanned2,155 server-visible instances with no findings/truncation. The main 08 client scan inspected 2,342 nodes and found zero audio sources/other Audio-class objects, also without truncation. Both are bounded observations of the inspected instance trees at that time. They do not certify all future effects, complete campaign silence or experience voice configuration. Keep the no-audio policy; do not add audio feedback or relax guards to make a test pass.

The main 05 identity a449d9b962a4… was verified at 06:09:42; its O shortcut still reached Studio zoomOutAction. Main 08 identity 3343bd4af705… was verified at 06:38:28. Native Tab opened/closed Hub Options; [capture](../docs/reaudit-evidence-2026-09-05/build08-tab-options.png). This does not pass Active/Draft/controller behavior or O itself. Main 08 also includes bootstrap cleanup, pre-allowance dodge spatial validation and undefined weak-tween removal; only the tested behavior has engine acceptance.

After QA08, the root closed its own Studio instance. Commit headroom recovered to roughly 5.0 GiB with 1.9 GiB physical free, but a single play session had consumed roughly 3.5 GiB and repeatedly left about 1.5 GiB. Stage/lifecycle/Active smoke, continuous campaign, device/rig/asset/performance/provider checks remain open. Resume them only with sustainable headroom. Main09/QA09 completed the dialogue source repair and static packaging; no 09 engine was launched and no 08 result certifies the repaired dialogue.
