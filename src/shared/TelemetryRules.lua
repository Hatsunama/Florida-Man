--!strict
-- Pure, bounded event semantics; provider field names belong to AnalyticsAdapter.
local TelemetryRules = {}
function TelemetryRules.Dimensions(fields: {[string]: any}?): (number, {string})
	local f: {[string]: any} = fields or {}
	local value = if type(f.value)=='number' then f.value else 1
	if value ~= value or math.abs(value)==math.huge then value=1 end
	local stage = tostring(f.stage or 'session')
	local reason = tostring(f.reason or f.where or (if f.ok == 1 then 'success' elseif f.ok == 0 then 'failure' else 'event'))
	local cohort = tostring(f.device or 'unknown')
	return value, {string.sub(stage,1,64),string.sub(reason,1,48),string.sub(cohort,1,16)}
end
function TelemetryRules.FtueOutcome(startedAt: number?, now: number, coldOne: boolean, ending: boolean): string?
	if not startedAt then return nil end
	if coldOne then return if now-startedAt <= 60 then 'success' else 'timeout' end
	if now-startedAt >= 60 then return 'timeout' end
	if ending then return 'abandon' end
	return nil
end
return table.freeze(TelemetryRules)
