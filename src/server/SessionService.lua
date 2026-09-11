--!strict
-- Owns admission and callback lifetime. The world belongs to exactly one admitted player.
local SessionService = {}
type Scope = {id: string, generation: number, tasks: {[thread]: boolean}, connections: {RBXScriptConnection}, namedConnections: {[string]: RBXScriptConnection?}}
local owner: Player? = nil
local scopes: {[Player]: Scope} = {}

function SessionService.Acquire(player: Player): boolean
	if owner and owner ~= player then return false end
	if scopes[player] then return true end
	owner = player
	scopes[player] = {id = tostring(player.UserId) .. ':' .. game.JobId .. ':' .. tostring(os.clock()), generation = 0, tasks = {}, connections = {}, namedConnections = {}}
	return true
end

function SessionService.IsOwner(player: Player): boolean
	return owner == player and scopes[player] ~= nil and player.Parent ~= nil
end

function SessionService.GetIdentity(player: Player): (string, number)
	local scope = scopes[player]
	return if scope then scope.id else '', if scope then scope.generation else 0
end

function SessionService.Advance(player: Player): number
	local scope = scopes[player]
	if not scope then return 0 end
	scope.generation += 1
	for pending in scope.tasks do
		if pending ~= coroutine.running() then pcall(task.cancel, pending) end
	end
	table.clear(scope.tasks)
	return scope.generation
end

function SessionService.Delay(player: Player, seconds: number, callback: () -> ())
	local scope = scopes[player]
	if not scope then return end
	local generation = scope.generation
	local pending: thread
	pending = task.delay(seconds, function()
		scope.tasks[pending] = nil
		if not SessionService.IsOwner(player) or scopes[player] ~= scope or scope.generation ~= generation then return end
		local ok, err = pcall(function() callback(); return true end)
		if not ok then warn('[Florida Man] Scoped callback failed: ' .. tostring(err)) end
	end)
	scope.tasks[pending] = true
end

function SessionService.TrackConnection(player: Player, connection: RBXScriptConnection)
	local scope = scopes[player]
	if scope then table.insert(scope.connections, connection) else connection:Disconnect() end
end

function SessionService.Release(player: Player)
	local scope = scopes[player]
	if not scope then return end
	SessionService.Advance(player)
	for _, connection in scope.connections do connection:Disconnect() end
	for _, connection in scope.namedConnections do if connection then connection:Disconnect() end end
	scopes[player] = nil
	if owner == player then owner = nil end
end

function SessionService.SetConnection(player: Player, key: string, connection: RBXScriptConnection?)
	local scope=scopes[player]
	if not scope then if connection then connection:Disconnect() end; return end
	local old=scope.namedConnections[key]
	if old then old:Disconnect() end
	scope.namedConnections[key]=connection
end

function SessionService.GetPendingCount(player: Player): number
	local scope = scopes[player]
	local count = 0
	if scope then for _ in scope.tasks do count += 1 end end
	return count
end

function SessionService.GetConnectionCount(player: Player): number
	local scope=scopes[player]
	local count=0
	if scope then
		for _,connection in scope.connections do if connection.Connected then count+=1 end end
		for _,connection in scope.namedConnections do if connection and connection.Connected then count+=1 end end
	end
	return count
end

return SessionService
