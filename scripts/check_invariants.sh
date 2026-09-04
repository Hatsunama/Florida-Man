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
check "lookAlong facing" 'lookAlong' src/client/Controllers/MovementController.lua
check "SPAWN_X = 18" 'SPAWN_X = 18' src/shared/Constants.lua
check "ClickablePrompt" 'ClickablePrompt = true' src/server/WorldBuilder.lua
check "HasIFrames server" 'HasIFrames' src/server/CombatService.lua
check "CombatService require GS" 'CombatService' src/server/GameService.lua
check "MobileControls" 'MobileControls' src/client/init.client.lua
check "SoundId smoke" 'SoundId = soundId' src/server/WorldBuilder.lua
check "OilSlow" 'OilSlow' src/server/GameService.lua
exit $fail
