# Audit verification evidence — 2026-09-04

Revision: `1bff8c516fd0dfed08f991e0c23c008c665f707d`. Source was not modified.

- `compiler.json`: official Luau 0.737 Windows compiler, `luau-compile.exe --null <file>` over all 48 source files. 47 passed; HazardService failed at line 131 on reserved keyword `until`. This is compilation, not Roblox-aware type analysis or an engine execution test.
- `invariants.txt`: existing `scripts/check_invariants.sh`, Git Bash, exit 0, 160 OK lines. These are mostly textual checks and do not establish runtime correctness.
- `service-connections.json`: a narrow source scan of named `*Service.Method()` calls against matching definitions. It identified missing `EnemyService.UpdateSpillfatherSlickRing`; this is not a complete call-graph or dynamic-dispatch proof.
- `camera-math.json`: scalar execution of the exact camera X deadzone and spring equations. First cases cover a short stationary correction; subsequent cases move 18 studs/second for 3 seconds and stop for 2. This verifies the numerical defect independently of Roblox rendering. It does not prove a screenshot or live camera trace was captured.
- `place-source-comparison.json`: XML-only read of the existing ignored `FloridaMan.rbxlx`; all 48 embedded sources exactly match current source after newline normalization. The place was neither edited nor opened in Studio.

Rojo 7.7.0 additionally built `default.project.json` successfully into a temporary `FloridaMan-audit.rbxlx`. Packaging succeeds despite the source syntax failure. The user's existing place and lock were left untouched.

Tools were downloaded from their official GitHub releases into the operating-system temporary directory, not added as project dependencies: [Luau releases](https://github.com/luau-lang/luau/releases/tag/0.737), [Rojo 7.7.0](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0).

Roblox Studio playtests, screenshots, live DataStore fault injection, multi-client execution, imported asset permissions, and device profiling were not performed. The report identifies those acceptance checks explicitly.

The Codex Security tool finalized scan `a007184d-8d78-47b9-a857-2ab55d5827af` with three medium findings and partial formal source coverage. Unmodified copies of the generated report and sealed canonical JSON files are in `security/`. No live exploit was executed. The tool's working-tree-change warning reflects newly added audit artifacts; `git diff -- src default.project.json rokit.toml scripts README.md` remained empty.

Tool-reported usage for the security scan was 7,970,508 total tokens across three recorded threads, including 7,614,848 cached input tokens and 49,186 output tokens. This is the tool's cumulative accounting, not a count of unique source tokens or a billing estimate. TAC status could not be verified because the security-access connector was disconnected; local source review and report generation completed.
