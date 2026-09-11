--!strict
-- Fixed coordinates make endpoint/support guarantees independent of random decor.
local LayoutPlan = {}
export type Span = { first: number, last: number, gap: boolean }
export type StageLayout = { length: number, index: number?, setPiece: string?, rescueTurtles: number?,
	waves: { { atProgress: number } } }

function LayoutPlan.Build(length: number, stageIndex: number, allowGaps: boolean, reservations: { number }?): { Span }
	local spans: { Span } = {}
	local cursor = -10
	local finish = length + 20
	local safe: { number } = reservations or {}
	local gapWidth = 6 -- conservative baseline; never scaled by stage/difficulty
	if allowGaps and stageIndex >= 5 then
		for _, fraction in { 0.28, 0.70 } do
			local center = math.floor(length * fraction)
			local allowed = center > 35 and center < length - 45 and math.abs(center - length * 0.48) > 32
			for _, x in safe do
				if math.abs(center - x) < 16 then allowed = false end
			end
			if allowed then
				table.insert(spans, { first = cursor, last = center - gapWidth / 2, gap = false })
				table.insert(spans, { first = center - gapWidth / 2, last = center + gapWidth / 2, gap = true })
				cursor = center + gapWidth / 2
			end
		end
	end
	table.insert(spans, { first = cursor, last = finish, gap = false })
	return spans
end

function LayoutPlan.HasSupport(spans: { Span }, x: number, clearance: number?): boolean
	local pad = clearance or 0
	for _, span in spans do
		if not span.gap and x - pad >= span.first and x + pad <= span.last then return true end
	end
	return false
end

-- Set-piece collision must respect the same gaps as the ground plan.
function LayoutPlan.SupportedSlices(spans: { Span }, first: number, last: number): { Span }
	local slices: { Span } = {}
	for _, span in spans do
		local a, b = math.max(first, span.first), math.min(last, span.last)
		if not span.gap and b > a then table.insert(slices, {first=a,last=b,gap=false}) end
	end
	return slices
end

function LayoutPlan.ForStage(stage: StageLayout, spawnX: number): { Span }
	local length = stage.length
	local reservations = { spawnX, length - 6, length * 0.48 - 10, length * 0.82 }
	for _, wave in stage.waves do table.insert(reservations, length * wave.atProgress + 16) end
	for i = 1, stage.rescueTurtles or 0 do table.insert(reservations, length * (0.2 + 0.12 * i)) end
	local allowGaps = stage.setPiece == "bargeGaps" or stage.setPiece == "canalPads"
	return LayoutPlan.Build(length, stage.index or 0, allowGaps, reservations)
end

return LayoutPlan
