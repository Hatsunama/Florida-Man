local Layout = require("../src/shared/LayoutPlan")
local lengths = { 200, 220, 230, 230, 240, 250, 280, 260, 260, 250, 260, 250, 270, 270, 280, 260, 270, 280, 250, 320 }
for index, length in lengths do
	for _, gaps in { false, true } do
		local spans = Layout.Build(length, index, gaps, { length * 0.42, length * 0.82, 65, 90, 115 })
		assert(spans[1].first == -10)
		assert(spans[#spans].last == length + 20)
		assert(Layout.HasSupport(spans, 6, 3), "supported spawn")
		assert(Layout.HasSupport(spans, length - 6, 4), "supported exit")
		assert(Layout.HasSupport(spans, length * 0.48 - 10, 5), "supported room")
		for i, span in spans do
			assert(span.last > span.first)
			if i > 1 then assert(spans[i - 1].last == span.first, "route partitions fixed endpoints") end
			if span.gap then assert(span.last - span.first <= 6, "bounded baseline gap") end
		end
	end
end
local reserved = Layout.Build(320, 20, true, { math.floor(320 * 0.28), math.floor(320 * 0.7) })
assert(#reserved == 1, "required landings override gap decoration")
local stage = { length = 320, index = 20, setPiece = "bargeGaps", rescueTurtles = 0, waves = {} }
assert(#Layout.ForStage(stage, 18) == 5, "authored gap set piece permits both unreserved gaps")
stage.rescueTurtles = 1
assert(#Layout.ForStage(stage, 18) == 3, "runtime turtle placement reserves its landing")
stage.setPiece = "helipadWind"
assert(#Layout.ForStage(stage, 18) == 1, "non-gap set pieces stay solid")
local barge={length=270,index=17,setPiece='bargeGaps',rescueTurtles=0,waves={{atProgress=.1},{atProgress=.28},{atProgress=.48},{atProgress=.65},{atProgress=.82}}}
local bargeSpans=Layout.ForStage(barge,18)
assert(not Layout.HasSupport(bargeSpans,75,0),'production BargeCrossing retains its reserved real gap')
local slices=Layout.SupportedSlices(bargeSpans,55,81)
assert(#slices==2 and slices[1].last==72 and slices[2].first==78,'first deck must split around real gap')
for i=1,5 do
	local x=20+i*48
	for _,slice in Layout.SupportedSlices(bargeSpans,x-13,x+13) do
		assert(Layout.HasSupport(bargeSpans,(slice.first+slice.last)*.5,(slice.last-slice.first)*.5),'every deck body stays within supported spans')
	end
end
print("PASS: 20 stage lengths, production BargeCrossing deck gap, reservations and supported set-piece slices")
