local Window=require('../src/shared/MetricsWindow')
local samples=Window.New(20)
assert(Window.Summary(samples).count==0)
for n=1,20 do Window.Add(samples,n) end
local full=Window.Summary(samples)
assert(full.count==20 and full.p50==10 and full.p95==19 and full.max==20)
for n=21,40 do Window.Add(samples,n) end
local rolled=Window.Summary(samples)
assert(rolled.count==20 and rolled.p50==30 and rolled.p95==39 and rolled.max==40)
Window.Add(samples,0/0); Window.Add(samples,math.huge); Window.Add(samples,-1)
assert(Window.Summary(samples).p50==30)
Window.Add(samples,0)
assert(Window.Summary(samples).count==20 and Window.Summary(samples).p50==30)
print('metrics: bounded eviction, percentiles, empty and invalid samples passed')
