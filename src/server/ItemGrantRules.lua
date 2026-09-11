--!strict
-- Pure transaction/offer rules; service adapters own state publication and saves.
local Rules = {}
function Rules.NewJournal(): any
	return {lastSequence = 0, results = {}, order = {}}
end

function Rules.CheckCommand(journal: any, action: string, payload: any): (boolean, any?, string?)
	if type(payload) ~= "table" or type(payload.requestId) ~= "string" or #payload.requestId < 1 or #payload.requestId > 96
		or type(payload.sequence) ~= "number" or payload.sequence ~= payload.sequence or payload.sequence % 1 ~= 0
		or payload.sequence < 1 or payload.sequence > 1000000000 then
		return false, nil, "Refresh the shop before trying again."
	end
	local cached = journal.results[payload.requestId]
	if cached then
		if cached.sequence == payload.sequence and cached.command == action then return false, cached, nil end
		return false, nil, "That request ID was already used."
	end
	if payload.sequence <= journal.lastSequence then return false, nil, "That request is out of date." end
	return true, nil, nil
end

function Rules.RememberCommand(journal: any, result: any)
	journal.lastSequence = result.sequence
	journal.results[result.requestId] = result
	table.insert(journal.order, result.requestId)
	if #journal.order > 64 then journal.results[table.remove(journal.order, 1)] = nil end
end

Rules.RARITIES = {"Common", "Rare", "Unique", "Legendary"}
Rules.UPGRADE_COST = {Common = 20, Rare = 45, Unique = 90}
Rules.SMASH_REFUND = {Common = 5, Rare = 12, Unique = 25, Legendary = 50}
function Rules.Grant(items: {string}, capacity: number, itemId: any, replaceIndex: any, lookup: (string) -> any): ({string}?, string)
	if type(itemId) ~= "string" or not lookup(itemId) then return nil, "Unknown item." end
	if type(capacity) ~= "number" or capacity ~= capacity or capacity % 1 ~= 0 or capacity < 3 or capacity > 6 then return nil, "Invalid inventory capacity." end
	if #items > capacity then return nil, "Inventory needs recovery." end
	local existing = table.find(items, itemId)
	if existing and existing ~= replaceIndex then return nil, "You already own that item." end
	if existing then return nil, "Choose a different item to replace." end
	local result = table.clone(items)
	if replaceIndex ~= nil then
		if type(replaceIndex) ~= "number" or replaceIndex ~= replaceIndex or replaceIndex % 1 ~= 0 or replaceIndex < 1 or replaceIndex > #items then
			return nil, "Choose an existing item to replace."
		end
		result[replaceIndex] = itemId
	elseif #items < capacity then
		table.insert(result, itemId)
	else
		return nil, "Choose an item to replace, or skip this reward."
	end
	-- One copy of each item per run; a single offer grants once.
	return result, "Item selected."
end

function Rules.ValidateOffer(offer: any, generation: number, payload: any): (boolean, string)
	if type(payload) ~= "table" then return false, "Invalid reward selection." end
	if not offer or offer.consumed then return false, "That reward is no longer open." end
	if payload.offerId ~= offer.offerId or payload.generation ~= generation or offer.generation ~= generation then
		return false, "That reward belongs to an earlier stage."
	end
	if payload.skip == true then return true, "Reward skipped." end
	if type(payload.itemId) ~= "string" or not offer.allowed[payload.itemId] then return false, "Choose one of the offered items." end
	return true, "Reward selected."
end

function Rules.HubTransaction(state: any, action: string, payload: any, lookup: (string) -> any): (any?, string)
	if not state.inHub or state.runActive or (state.phase ~= nil and state.phase ~= "Hub") then return nil, "Return to the bonfire to change your loadout." end
	if type(payload) ~= "table" or type(payload.personaId) ~= "string" then return nil, "Invalid persona selection." end
	if payload.generation ~= state.generation then return nil, "That request belongs to an earlier visit. Reopen the shop." end
	local id = payload.personaId
	local selected = table.clone(state.personas)
	if action == "EquipPersona" and id == "" then
		if payload.slot ~= 2 or #selected < 2 then return nil, "Keep at least one persona equipped." end
		table.remove(selected, 2)
		return {personas = selected, activePersona = math.min(state.activePersona, #selected)}, "Persona slot cleared."
	end
	if not lookup(id) or state.unlockedPersonas[id] ~= true then return nil, "Unlock that persona first." end
	local rarity = state.personaRarity[id] or "Common"
	local index = table.find(Rules.RARITIES, rarity)
	if not index then return nil, "Invalid persona tier." end
	if action == "EquipPersona" then
		local slot = payload.slot
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 1 or slot > math.min(2, #selected + 1) then return nil, "Choose persona slot 1 or 2." end
		local other = table.find(selected, id)
		if other and other ~= slot then return nil, "That persona is already in the other slot." end
		if selected[slot] == id then return {}, "Already equipped." end
		selected[slot] = id
		return {personas = selected, activePersona = math.min(state.activePersona, #selected)}, "Persona equipped."
	elseif action == "UpgradePersona" then
		local cost = Rules.UPGRADE_COST[rarity]
		if not cost then return nil, "Already Legendary." end
		if state.sunburn < cost then return nil, "Need " .. tostring(cost) .. " Sunburn." end
		local tiers = table.clone(state.personaRarity); tiers[id] = Rules.RARITIES[index + 1]
		return {sunburn = state.sunburn - cost, personaRarity = tiers}, "Upgraded to " .. tiers[id] .. "."
	elseif action == "SmashPersona" then
		if id == "BeachBurnout" then return nil, "The starter persona cannot be smashed." end
		if table.find(selected, id) then return nil, "Remove that persona from both slots before smashing it." end
		local owned = table.clone(state.unlockedPersonas); owned[id] = nil
		local tiers = table.clone(state.personaRarity); tiers[id] = nil
		local refund = Rules.SMASH_REFUND[rarity]
		return {sunburn = math.min(1000000000, state.sunburn + refund), unlockedPersonas = owned, personaRarity = tiers}, "Smashed for " .. refund .. " Sunburn."
	end
	return nil, "Unknown shop action."
end

return Rules
