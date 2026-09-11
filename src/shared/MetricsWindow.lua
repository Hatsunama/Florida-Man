--!strict
-- Bounded rolling measurements; nearest-rank percentiles describe collected samples only.
local Window={}
export type SampleWindow={values: {number}, nextIndex: number, capacity: number}
function Window.New(capacity: number): SampleWindow
	assert(capacity>=1 and capacity==math.floor(capacity))
	return {values={},nextIndex=1,capacity=capacity}
end
function Window.Add(window: SampleWindow,value: number)
	if value~=value or math.abs(value)==math.huge or value<0 then return end
	window.values[window.nextIndex]=value
	window.nextIndex=window.nextIndex%window.capacity+1
end
function Window.Summary(window: SampleWindow): {count: number,p50: number,p95: number,max: number}
	local sorted=table.clone(window.values)
	table.sort(sorted)
	local count=#sorted
	if count==0 then return {count=0,p50=0,p95=0,max=0} end
	return {count=count,p50=sorted[math.ceil(count*0.5)],p95=sorted[math.ceil(count*0.95)],max=sorted[count]}
end
return table.freeze(Window)
