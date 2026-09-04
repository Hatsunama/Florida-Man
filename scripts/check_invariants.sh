#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
check() {
  if rg -q "$2" "$ROOT/$3"; then
    echo "OK  $1"
  else
    echo "FAIL $1"
    fail=1
  fi
}
absent() {
  if rg -q "$2" "$ROOT/$3"; then
    echo "FAIL $1"
    fail=1
  else
    echo "OK  $1"
  fi
}
check "lookAlong facing" 'lookAlong' src/client/Controllers/MovementController.lua
check "SPAWN_X = 18" 'SPAWN_X = 18' src/shared/Constants.lua
check "ClickablePrompt" 'ClickablePrompt = true' src/server/WorldBuilder.lua
check "HasIFrames server" 'HasIFrames' src/server/CombatService.lua
check "CombatService require GS" 'CombatService' src/server/GameService.lua
check "MobileControls" 'MobileControls' src/client/init.client.lua
check "SoundId smoke" 'SoundId = soundId' src/server/WorldBuilder.lua
check "OilSlow" 'OilSlow' src/server/HazardService.lua
check "MetaService module" 'DataStoreService' src/server/MetaService.lua
check "MetaService require GS" 'MetaService' src/server/GameService.lua
check "HazardService require GS" 'HazardService' src/server/GameService.lua
check "DailyLuckBonus" 'DailyLuckBonus' src/shared/Balance.lua
check "Telegraph pool" 'FM_TelegraphPool' src/server/EnemyService.lua
check "Publish checklist" 'FTUE' docs/PUBLISH_CHECKLIST.md
# N0 hygiene
absent "RequestJump absent" 'RequestJump' src/
absent "Tagline no AudioDirector" 'AudioDirector' src/client/UI/Tagline.lua
absent "No SFX_SteveBeep play()" 'Play\("SFX_SteveBeep"' src/
check "EquipWeapon remote" 'EquipWeapon' src/shared/Remotes.lua
check "PickDraftItem itemSlots" 'itemSlots' src/server/DraftService.lua
check "DraftService module" 'DraftService' src/server/DraftService.lua
check "HubService module" 'HubService' src/server/HubService.lua
check "StageFlowService module" 'StageFlowService' src/server/StageFlowService.lua
check "CombatFacade module" 'CombatFacade' src/server/CombatFacade.lua
check "CombatFacade CombatService" 'CombatService' src/server/CombatFacade.lua
check "N0.1 hard itemSlots grant" 'GrantEnemyDrop' src/server/CombatFacade.lua
check "N0.2 skip-draft full" 'draft skipped' src/server/DraftService.lua
check "N0.4 mobile TryAttack" 'TryAttack' src/client/UI/MobileControls.lua
check "SpawnLocation SPAWN_X" 'Vector3\.new\(18, 0\.5, 0\)' src/server/init.server.lua
check "Types WeaponKind" 'WeaponKind' src/shared/Types.lua
check "Types MetaProfile" 'MetaProfile' src/shared/Types.lua
check "Types RunState" 'export type RunState' src/shared/Types.lua
# N1 line budget
GS_LINES=$(wc -l < "$ROOT/src/server/GameService.lua")
if [ "$GS_LINES" -le 400 ]; then
  echo "OK  GameService <=400 ($GS_LINES)"
else
  echo "FAIL GameService <=400 ($GS_LINES)"
  fail=1
fi
exit $fail
