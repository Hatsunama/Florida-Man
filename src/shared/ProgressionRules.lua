--!strict
-- Pure campaign rules. Presentation and transport cannot grant completion.
local Rules = {}

function Rules.ItemCapacity(stageIndex: number): number
	return math.clamp(3 + math.floor(math.max(0, stageIndex - 1) / 5), 3, 6)
end

function Rules.CanUnlockPersona(personaId: string, finaleCommitted: boolean): boolean
	return personaId ~= 'FireworksEnthusiast' or finaleCommitted
end

function Rules.RequiresMidRoom(stage: {index: number,isHub: boolean,waves: {any}}): boolean
	return not stage.isHub and stage.index>=3 and #stage.waves>0
end

function Rules.CanComplete(stage: {index: number,isHub: boolean, boss: string?, rescueTurtles: number, miniboss: string?, waves: {any},coldOnePickup: boolean?}, state: {bossDefeated: boolean, turtlesRescued: number, minibossSpawned: boolean, waveFlags: {[number]: boolean},midRoomState: string,coldOneTaken: boolean?}, outstanding: number): boolean
	if stage.isHub or outstanding > 0 then return false end
	if stage.coldOnePickup and not state.coldOneTaken then return false end
	if Rules.RequiresMidRoom(stage) and state.midRoomState~='cleared' then return false end
	if stage.boss and not state.bossDefeated then return false end
	if state.turtlesRescued < stage.rescueTurtles then return false end
	if stage.miniboss and not state.minibossSpawned then return false end
	for i in stage.waves do
		if not state.waveFlags[i] then return false end
	end
	return true
end

function Rules.Claim(ledger: {[string]: boolean}, key: string): boolean
	if ledger[key] then return false end
	ledger[key] = true
	return true
end

return table.freeze(Rules)
