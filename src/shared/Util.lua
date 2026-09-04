--!strict
local Util = {}

function Util.SafeUnit(v: Vector3): Vector3
	if v.Magnitude < 0.001 then
		return Vector3.zero
	end
	return v.Unit
end

function Util.Flatten(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function Util.LanePosition(x: number, y: number, laneZ: number): Vector3
	return Vector3.new(x, y, laneZ)
end

function Util.Clamp(n: number, a: number, b: number): number
	return math.clamp(n, a, b)
end

function Util.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Util.RarityColor(rarity: string): Color3
	if rarity == "Common" then
		return Color3.fromRGB(200, 200, 200)
	elseif rarity == "Rare" then
		return Color3.fromRGB(80, 160, 255)
	elseif rarity == "Unique" then
		return Color3.fromRGB(180, 80, 255)
	elseif rarity == "Legendary" then
		return Color3.fromRGB(255, 180, 40)
	end
	return Color3.fromRGB(255, 255, 255)
end

function Util.InscriptionColor(tag: string): Color3
	local map = {
		HUMID = Color3.fromRGB(80, 180, 200),
		FERAL = Color3.fromRGB(200, 90, 50),
		LUCKY = Color3.fromRGB(255, 210, 60),
		GREASY = Color3.fromRGB(160, 120, 40),
		HEROIC = Color3.fromRGB(90, 200, 140),
		CHAOS = Color3.fromRGB(255, 80, 160),
	}
	return map[tag] or Color3.fromRGB(255, 255, 255)
end

return Util
