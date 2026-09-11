--!strict
-- Developer diagnostics only. No rewards, permissions, or gameplay decisions depend on measurements.
local Players=game:GetService('Players')
local Stats=game:GetService('Stats')
local Window=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('MetricsWindow'))
local EnemyService=require(script.Parent:WaitForChild('EnemyService'))
local HazardService=require(script.Parent:WaitForChild('HazardService'))
local SessionService=require(script.Parent:WaitForChild('SessionService'))
local MetaService=require(script.Parent:WaitForChild('MetaService'))
local FunnelService=require(script.Parent:WaitForChild('FunnelService'))
local Metrics={}
local steps=Window.New(120)
local heartbeats=Window.New(120)
local commands=0
local rejected=0
local instances=0
for _ in workspace:GetDescendants() do instances+=1 end
workspace.DescendantAdded:Connect(function() instances+=1 end)
workspace.DescendantRemoving:Connect(function() instances=math.max(0,instances-1) end)
function Metrics.Command(accepted: boolean)
	commands+=1
	if not accepted then rejected+=1 end
end
function Metrics.Step(seconds: number) Window.Add(steps,seconds*1000) end
function Metrics.Heartbeat(seconds: number) Window.Add(heartbeats,seconds*1000) end
function Metrics.Snapshot(player: Player): any
	local memoryOk,memory=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
	return {
		at=os.clock(),simulationMs=Window.Summary(steps),serverHeartbeatMs=Window.Summary(heartbeats),
		workspaceDescendants=instances,serverMemoryMb=if memoryOk then memory else nil,luauHeapKiB=gcinfo(),
		hostiles=EnemyService.CountHostile(),pendingEnemies=EnemyService.GetPendingCount(),
		hazards=HazardService.GetRegisteredCount(),pendingSessionTasks=SessionService.GetPendingCount(player),
		sessionConnections=SessionService.GetConnectionCount(player),profile=MetaService.GetMetrics(),
		analytics=FunnelService.GetMetrics(),remoteRequests=commands,remoteRateRejected=rejected,
	}
end
local latest: any=nil
function Metrics.GetLatest(): any return latest end
task.spawn(function()
	while true do
		task.wait(5)
		local player: Player?=nil
		for _,candidate in Players:GetPlayers() do if SessionService.IsOwner(candidate) then player=candidate; break end end
		latest=if player then Metrics.Snapshot(player) else nil
	end
end)
game:GetService('RunService').Heartbeat:Connect(Metrics.Heartbeat)
return Metrics
