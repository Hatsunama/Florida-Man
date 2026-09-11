--!strict
-- Only mapped by the isolated QA builder. Registration does not run a test.
local RunService=game:GetService('RunService')
if not RunService:IsStudio() or not RunService:IsServer() or game.PlaceId~=0 then return end
local ServerScriptService=game:GetService('ServerScriptService')
local command=Instance.new('BindableFunction')
command.Name='StudioAuditCommand'
local busy=false
command.OnInvoke=function(name: unknown, argument: unknown): any
	if busy then return {ok=false,reason='A QA command is already running.'} end
	if typeof(name)~='string' then return {ok=false,reason='Expected an allowlisted command.'} end
	if name~='ListStages' and name~='ResetToStage' and name~='Snapshot' and name~='ScanAudio'
		and name~='RunStageSmoke' and name~='NearCaptainSteve' and name~='BeginTrace' and name~='Trace'
		and name~='RunLifecycleSmoke' then return {ok=false,reason='Unknown QA command.'} end
	if name=='ResetToStage' and (typeof(argument)~='string' or #argument>80) then return {ok=false,reason='Expected a stage id.'} end
	busy=true
	local ok,result=pcall(function(): any
		local audit=require(ServerScriptService:WaitForChild('StudioAudit'))
		if name=='ResetToStage' then return audit.ResetToStage(argument :: string)
		elseif name=='ListStages' then return audit.ListStages()
		elseif name=='Snapshot' then return audit.Snapshot()
		elseif name=='ScanAudio' then return audit.ScanAudio(8000)
		elseif name=='NearCaptainSteve' then return audit.NearCaptainSteve()
		elseif name=='BeginTrace' then return audit.BeginTrace()
		elseif name=='Trace' then return audit.Trace()
		elseif name=='RunLifecycleSmoke' then return audit.RunLifecycleSmoke()
		else return audit.RunStageSmoke() end
	end)
	busy=false
	return if ok then result else {ok=false,reason=string.sub(tostring(result),1,400)}
end
command.Parent=ServerScriptService
