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
# N2 trust & edges
absent "PendingDamage gone" 'PendingDamage' src/
check "OnPlayerHit callback" 'SetOnPlayerHit' src/server/EnemyService.lua
check "CombatFacade registers OnPlayerHit" 'SetOnPlayerHit' src/server/CombatFacade.lua
absent "No attack-rescue TryRescue" 'TryRescue' src/server/CombatFacade.lua
check "Rescue debounce" 'RESCUE_DEBOUNCE' src/server/EnemyService.lua
check "OilSlowUntil hazard" 'OilSlowUntil' src/server/HazardService.lua
check "OIL_SLOW_MULT distinct" 'OIL_SLOW_MULT' src/shared/Constants.lua
check "Hangover/OilSlow min-stack" 'OIL_SLOW_MULT' src/server/RunContext.lua
check "Meta schema version" 'META_SCHEMA_VERSION' src/shared/Constants.lua
check "Meta dirty/re-entrancy" 'saving\[player\]' src/server/MetaService.lua
check "Meta run capturer" 'RegisterRunCapturer' src/server/MetaService.lua
check "Cloud offline toast" 'Cloud save offline' src/server/MetaService.lua
check "Combat remote rate limit" 'takeToken' src/server/GameService.lua
check "Soft-fall toast cap" 'SOFT_FALL_TOAST_MAX' src/server/HazardService.lua
check "Soft-fall solid sample" 'LastSolidX' src/server/HazardService.lua
check "MidGate empty waves unlock" 'waves == 0' src/server/StageFlowService.lua
absent "Client hangoverMult gone" 'hangoverMult' src/client/Controllers/MovementController.lua

# N1 line budget
GS_LINES=$(wc -l < "$ROOT/src/server/GameService.lua")
if [ "$GS_LINES" -le 400 ]; then
  echo "OK  GameService <=400 ($GS_LINES)"
else
  echo "FAIL GameService <=400 ($GS_LINES)"
  fail=1
fi

# N3 catalog honesty
check "BonfireEmber ember special" 'special="ember"' src/shared/Items.lua
check "Ranged pierce cap" 'RANGED_PIERCE_HITS' src/shared/Constants.lua
check "PierceLeft combat" 'pierceLeft' src/server/CombatService.lua
check "hoaCone damage tick" 'hk == "hoaCone"' src/server/HazardService.lua
check "HOA_CONE_DAMAGE" 'HOA_CONE_DAMAGE' src/shared/Constants.lua
check "GREASY oilResist set" 'oilResist' src/shared/Items.lua
check "OilResist attr" 'OilResist' src/server/RunContext.lua
check "Ember dodge buff" 'EMBER_BUFF_DURATION' src/server/SwapService.lua
check "Weapon drops table N3" 'ConspiracyShack' src/server/StageFlowService.lua

# N4 options / a11y / dialogue UX
check "META_SCHEMA_VERSION = 2" 'META_SCHEMA_VERSION = 2' src/shared/Constants.lua
check "Meta store v2" 'FloridaMan_Meta_v2' src/server/MetaService.lua
check "Meta legacy v1 migrate" 'FloridaMan_Meta_v1' src/server/MetaService.lua
check "MuteMaster setting" 'MuteMaster' src/shared/Settings.lua
check "MuteSFX setting" 'MuteSFX' src/shared/Settings.lua
check "MuteAmbience setting" 'MuteAmbience' src/shared/Settings.lua
check "ReduceMotion setting" 'ReduceMotion' src/shared/Settings.lua
check "TextSpeed setting" 'TextSpeed' src/shared/Settings.lua
check "AudioDirector ApplyMute" 'ApplyMute' src/client/Controllers/AudioDirector.lua
check "Tagline text speed" 'TypewriterDelay' src/client/UI/Tagline.lua
check "Tagline skip/dismiss" 'tap / click to skip' src/client/UI/Tagline.lua
absent "Tagline no AudioDirector" 'AudioDirector' src/client/UI/Tagline.lua
check "HUD Options panel" 'FM_Options' src/client/UI/HUD.lua
check "Options ≥44px rows" '0, 48' src/client/UI/HUD.lua
check "ReduceMotion hitstop" 'IsReduceMotion' src/client/Controllers/MovementController.lua
check "ReduceMotion shake" 'IsReduceMotion' src/client/Controllers/CameraController.lua
check "SyncSettings TextSpeed" 'TextSpeed' src/server/GameService.lua
absent "Newspaper open sting" 'SFX_NewspaperSting' src/client/UI/Newspaper.lua

# N5 level verbs
check "WATER_TIMEOUT constant" 'WATER_TIMEOUT' src/shared/Constants.lua
check "CONVEYOR_FLIP_PERIOD" 'CONVEYOR_FLIP_PERIOD' src/shared/Constants.lua
check "TURTLE_ESCORT_RADIUS" 'TURTLE_ESCORT_RADIUS' src/shared/Constants.lua
check "WIND_OPPOSE_MULT" 'WIND_OPPOSE_MULT' src/shared/Constants.lua
check "Stages.LevelVerb" 'function Stages.LevelVerb' src/shared/Stages.lua
check "Story MidGateLockLine" 'MidGateLockLine' src/shared/Story.lua
check "Story VerbToast" 'VerbToast' src/shared/Story.lua
check "Water timeout soft-fall" 'WATER_TIMEOUT' src/server/HazardService.lua
check "Conveyor flip signed" 'ConveyorDir' src/server/HazardService.lua
check "WindOpposeJump hazard" 'WindOpposeJump' src/server/HazardService.lua
check "WorldBuilder LevelVerb attr" 'LevelVerb' src/server/WorldBuilder.lua
check "WorldBuilder ConveyorFlipPeriod" 'ConveyorFlipPeriod' src/server/WorldBuilder.lua
check "Platform scalingTier density" 'scalingTier adds real' src/server/WorldBuilder.lua
check "Canal pad-only setPiece" 'pad-only traversal' src/server/WorldBuilder.lua
check "Barge wind gaps" 'wind opposing jumps' src/server/WorldBuilder.lua
check "Turtle EscortGoalX" 'EscortGoalX' src/server/StageFlowService.lua
check "MidGate first-lock Tagline" 'midGateAct' src/server/StageFlowService.lua
check "Verb toast LoadStage" 'VerbToast' src/server/StageFlowService.lua
check "Turtle escort AI" 'EscortEnabled' src/server/EnemyService.lua
check "Late denser telegraphs" 'stageIdx >= 17' src/server/EnemyService.lua
absent "SafetyFloor regression" 'SafetyFloor' src/

# N6 combat facade depth
check "AttackService module" 'AttackService' src/server/AttackService.lua
check "SkillService module" 'SkillService' src/server/SkillService.lua
check "SwapService module" 'SwapService' src/server/SwapService.lua
check "Facade delegates DoAttack" 'AttackService.DoAttack' src/server/CombatFacade.lua
check "Facade delegates DoSkill" 'SkillService.DoSkill' src/server/CombatFacade.lua
check "Facade delegates DoSwap" 'SwapService.DoSwap' src/server/CombatFacade.lua
check "Moveset cancelAfter" 'cancelAfter' src/server/CombatService.lua
check "Types MovesetHit cancel" 'cancelAfter' src/shared/Types.lua
check "attackReadyAt StateUpdate" 'attackReadyAt' src/server/RunContext.lua
check "Client SyncAttackReady" 'SyncAttackReady' src/client/Controllers/InputController.lua
check "HUD FlashCancel" 'FlashCancel' src/client/UI/HUD.lua
check "HUD FlashPunish" 'FlashPunish' src/client/UI/HUD.lua
check "FOAM_FIRE_MULT" 'FOAM_FIRE_MULT' src/shared/Constants.lua
check "Foam fire secondary" 'FOAM_FIRE_MULT' src/server/AttackService.lua
check "Net RootedUntil" 'RootedUntil' src/server/AttackService.lua
check "Enemy RootedUntil gate" 'RootedUntil' src/server/EnemyService.lua
check "THROW_ARC_HEIGHT" 'THROW_ARC_HEIGHT' src/server/CombatService.lua
check "GameService remotes only attack" 'CombatFacade.DoAttack' src/server/GameService.lua
absent "No DoAttack body in GameService" 'function GameService.DoAttack' src/server/GameService.lua
CF_LINES=$(wc -l < "$ROOT/src/server/CombatFacade.lua")
if [ "$CF_LINES" -le 300 ]; then
  echo "OK  CombatFacade <=300 ($CF_LINES)"
else
  echo "FAIL CombatFacade <=300 ($CF_LINES)"
  fail=1
fi

# N7 art / anim pipeline (no fake Mesh IDs)
check "ArtAssets module" 'IsValidAssetId' src/shared/ArtAssets.lua
check "ArtAssets TryCloneMeshModel" 'TryCloneMeshModel' src/shared/ArtAssets.lua
check "ArtAssets ART_KIT_PART" 'InEngine_v3' src/shared/ArtAssets.lua
check "EnemyFactory mesh try" 'tryMeshEnemy' src/server/EnemyFactory.lua
check "EnemyFactory ArtAssets" 'ArtAssets' src/server/EnemyFactory.lua
check "WorldBuilder ArtAssets" 'ArtAssets' src/server/WorldBuilder.lua
check "WorldBuilder CaptainSteve mesh try" 'TryCloneMeshModel\("CaptainSteve"\)' src/server/WorldBuilder.lua
check "AnimController uses ArtAssets" 'ArtAssets.GetAnimationId' src/client/Controllers/AnimController.lua
check "AnimController procedural skill" 'poseKind = "skill"' src/client/Controllers/AnimController.lua
check "AnimController PlaySwap" 'function AnimController.PlaySwap' src/client/Controllers/AnimController.lua
check "AnimController ReduceMotion scale" 'IsReduceMotion' src/client/Controllers/AnimController.lua
check "VFX particleBudget ReduceMotion" 'particleBudget' src/client/Controllers/VFX.lua
check "VFX bash/grab arcs" 'kind == "bash"' src/client/Controllers/VFX.lua
check "ReduceMotion hitstop" 'IsReduceMotion' src/client/Controllers/MovementController.lua
check "ReduceMotion shake" 'IsReduceMotion' src/client/Controllers/CameraController.lua
check "Persona BodyColors + Highlight" 'FM_PersonaHighlight' src/server/RunContext.lua
check "ART_PIPELINE honesty" 'do \*\*not\*\* invent' docs/ART_PIPELINE.md
check "Rojo Assets.Meshes folder" '"Meshes"' default.project.json

# Reject invented / placeholder rbxassetid numeric stubs in src (allow comments mentioning the prefix)
if rg -n 'rbxassetid://(0+|00+|000+|1234+|1111+|9999+)([^0-9]|$)' "$ROOT/src" ; then
  echo "FAIL N7 no placeholder rbxassetid stubs"
  fail=1
else
  echo "OK  N7 no placeholder rbxassetid stubs"
fi
# Any non-empty rbxassetid in src must pass through ArtAssets validation path — for now expect ZERO concrete IDs
if rg -n 'AnimationId\s*=\s*"rbxassetid://[1-9]' "$ROOT/src" ; then
  echo "FAIL N7 direct AnimationId assignment (use ArtAssets registry)"
  fail=1
else
  echo "OK  N7 no direct AnimationId rbxassetid assignments"
fi
if rg -n 'MeshId\s*=\s*"rbxassetid://' "$ROOT/src" ; then
  echo "FAIL N7 MeshId rbxassetid in src"
  fail=1
else
  echo "OK  N7 no MeshId rbxassetid in src"
fi

exit $fail
