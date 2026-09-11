--!strict
-- Pure hit geometry used by simulation and deterministic regression fixtures.
local Geometry = {}

function Geometry.MuzzleY(rootY: number, feetDistance: number): number
	return rootY - feetDistance + 1.2
end

function Geometry.GroundedCenterY(rootY: number, feetDistance: number, height: number): number
	return rootY - feetDistance + height * 0.5
end

function Geometry.HealFromDamage(health: number, maxHealth: number, damageApplied: number, rate: number): number
	return math.min(maxHealth, health + math.max(0, damageApplied) * rate)
end

function Geometry.SegmentBox(
	ax: number, ay: number, az: number, bx: number, by: number, bz: number,
	cx: number, cy: number, cz: number, hx: number, hy: number, hz: number
): number?
	local first, last = 0, 1
	for _, axis in { { ax - cx, bx - ax, hx }, { ay - cy, by - ay, hy }, { az - cz, bz - az, hz } } do
		local origin, delta, extent = axis[1], axis[2], axis[3]
		if math.abs(delta) < 0.000001 then
			if math.abs(origin) > extent then return nil end
		else
			local t1, t2 = (-extent - origin) / delta, (extent - origin) / delta
			if t1 > t2 then t1, t2 = t2, t1 end
			first, last = math.max(first, t1), math.min(last, t2)
			if first > last then return nil end
		end
	end
	return first
end

function Geometry.BossPhase(health: number, maxHealth: number): number
	local pct = if maxHealth > 0 then health / maxHealth else 1
	return if pct <= 0.33 then 3 elseif pct <= 0.66 then 2 else 1
end

function Geometry.Damage(health: number, requested: number): number
	if health ~= health or requested ~= requested or requested == math.huge or requested <= 0 then return 0 end
	return math.min(math.max(0, health), requested)
end

function Geometry.NextCombo(previous: number, now: number, previousReadyAt: number, grace: number): number
	if now > previousReadyAt + grace then return 1 end
	return previous % 3 + 1
end

return Geometry
