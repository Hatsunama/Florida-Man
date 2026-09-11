--!strict
-- Only this module knows Roblox analytics field keys. Queue work never blocks simulation.
local AnalyticsService=game:GetService('AnalyticsService')
local Rules=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('TelemetryRules'))
local Adapter={}
local queue: {any}={}
local dropped=0
local failed=0
local lastWarning=0

function Adapter.Enqueue(player: Player,event: string,fields: {[string]: any}?)
	if #queue >= 64 then dropped+=1; return end
	local value,dimensions=Rules.Dimensions(fields)
	table.insert(queue,{player=player,event=event,value=value,dimensions=dimensions})
end
function Adapter.GetMetrics(): any return {queued=#queue,dropped=dropped,failed=failed} end

task.spawn(function()
	while true do
		task.wait(0.2)
		local record=table.remove(queue,1)
		if not record then continue end
		local ok,err=pcall(function()
			AnalyticsService:LogCustomEvent(record.player,record.event,record.value,{
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name]=record.dimensions[1],
				[Enum.AnalyticsCustomFieldKeys.CustomField02.Name]=record.dimensions[2],
				[Enum.AnalyticsCustomFieldKeys.CustomField03.Name]=record.dimensions[3],
			})
		end)
		if not ok then
			failed+=1
			if os.clock()-lastWarning>30 then lastWarning=os.clock(); warn('[Florida Man] Analytics delivery failed: '..tostring(err)) end
		end
	end
end)
return Adapter
