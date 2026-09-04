--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Stages = require(Shared:WaitForChild("Stages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))

local HazardService = {}

export type HazardCtx = {
	runActive: boolean,
	stageId: string,
	stageIndex: number,
	checkpointX: number,
	moveSpeed: number,
}

local function triggerSoftFall(
	player: Player,
	char: Model,
	hrp: BasePart,
	st: HazardCtx,
	toast: ((Player, string) -> ())?,
	reason: string?
)
	local lastFall = char:GetAttribute("LastSoftFallAt")
	if typeof(lastFall) == "number" and os.clock() - lastFall <= 1.0 then
		return
	end
	char:SetAttribute("LastSoftFallAt", os.clock())
	char:SetAttribute("WaterSince", nil)
	local solidX = char:GetAttribute("LastSolidX")
	local solidY = char:GetAttribute("LastSolidY")
	local cx = st.checkpointX or Constants.SPAWN_X
	if typeof(solidX) == "number" then
		cx = solidX
	elseif typeof(cx) ~= "number" or cx < Constants.SPAWN_X then
		cx = Constants.SPAWN_X
	end
	local cy = if typeof(solidY) == "number" then solidY else 5
	hrp.CFrame = CFrame.new(cx, cy, Constants.LANE_Z)
	hrp.AssemblyLinearVelocity = Vector3.zero
	local toasts = char:GetAttribute("SoftFallToasts")
	local n = if typeof(toasts) == "number" then toasts else 0
	if toast and n < Constants.SOFT_FALL_TOAST_MAX then
		char:SetAttribute("SoftFallToasts", n + 1)
		toast(player, reason or "Soft checkpoint — back on the lane.")
	end
	Remotes.Get("CombatEvent"):FireClient(player, { kind = "shake", amount = 0.4 })
	Remotes.Get("PlaySound"):FireClient(player, "SFX_Splash")
end

local function tickTimedHazard(part: BasePart): boolean
	local period = part:GetAttribute("HazardPeriod")
	if typeof(period) ~= "number" or period <= 0 then
		return true
	end
	local duty = (part:GetAttribute("HazardDuty") :: number?) or 0.5
	local phase = (os.clock() % period) / period
	local active = phase < duty
	part:SetAttribute("HazardActive", active)
	if active then
		part.Transparency = math.min(part.Transparency, 0.25)
	else
		part.Transparency = math.max(part.Transparency, 0.65)
	end
	return active
end

local function conveyorPushSigned(child: BasePart): number
	local base = math.abs((child:GetAttribute("ConveyorPush") :: number?) or 18)
	local period = (child:GetAttribute("ConveyorFlipPeriod") :: number?) or Constants.CONVEYOR_FLIP_PERIOD
	local phase = math.floor(os.clock() / math.max(0.5, period)) % 2
	local dir = if phase == 0 then 1 else -1
	child:SetAttribute("ConveyorDir", dir)
	-- Visual flip cue
	if dir > 0 then
		child.Color = Color3.fromRGB(70, 90, 120)
	else
		child.Color = Color3.fromRGB(120, 70, 90)
	end
	return base * dir
end

local function scanHazards(
	container: Instance,
	player: Player,
	charH: Model,
	hrpH: BasePart,
	stH: HazardCtx,
	applyDamage: (Player, number) -> (),
	toast: ((Player, string) -> ())?
): (boolean, boolean)
	local inDeepWater = false
	local onJumpPad = false

	for _, child in container:GetChildren() do
		if child:IsA("Folder") then
			local w, j = scanHazards(child, player, charH, hrpH, stH, applyDamage, toast)
			inDeepWater = inDeepWater or w
			onJumpPad = onJumpPad or j
			continue
		end
		if not child:IsA("BasePart") then
			continue
		end

		if child:GetAttribute("ConveyorMove") then
			local ox = (child:GetAttribute("ConveyorOriginX") :: number?) or child.Position.X
			local amp = (child:GetAttribute("ConveyorAmp") :: number?) or 6
			local spd = (child:GetAttribute("ConveyorSpeed") :: number?) or 1.2
			local nx = ox + math.sin(os.clock() * spd) * amp
			child.CFrame = CFrame.new(nx, child.Position.Y, Constants.LANE_Z)
		end
		if child:GetAttribute("Checkpoint") == true then
			if math.abs(child.Position.X - hrpH.Position.X) < 4 then
				stH.checkpointX = math.max(stH.checkpointX, child.Position.X)
			end
		end
		local hk = child:GetAttribute("Hazard")
		if typeof(hk) == "string" then
			local active = tickTimedHazard(child)
			local reach = if hk == "conveyor" then 6 elseif hk == "pipeSpray" then 4.5 elseif hk == "windPush" then 8 else 5
			if (child.Position - hrpH.Position).Magnitude < reach then
				if hk == "canalWater" or child:GetAttribute("WaterSlow") then
					inDeepWater = true
					local until = os.clock() + 0.9
					local prev = charH:GetAttribute("OilSlowUntil")
					if typeof(prev) ~= "number" or until > prev then
						charH:SetAttribute("OilSlowUntil", until)
					end
					charH:SetAttribute("OilSlow", true)
				elseif hk == "oilSlick" or hk == "sandSlow" or hk == "redTide" then
					local resist = charH:GetAttribute("OilResist") == true
					local until = os.clock() + (if resist then 0.55 else 1.2)
					local prev = charH:GetAttribute("OilSlowUntil")
					if typeof(prev) ~= "number" or until > prev then
						charH:SetAttribute("OilSlowUntil", until)
					end
					charH:SetAttribute("OilSlow", true)
				elseif (hk == "fryerOil" or hk == "slushPuddle" or hk == "pipeSpray" or hk == "slickRing" or hk == "movingSample") and active then
					if not CombatService.HasIFrames(player) and hrpH.Position.Y < child.Position.Y + 3.5 then
						local last = charH:GetAttribute("LastHazardAt")
						local dmg = (child:GetAttribute("HazardDamage") :: number?) or 5
						if charH:GetAttribute("OilResist") == true and (hk == "fryerOil" or hk == "slickRing" or hk == "pipeSpray") then
							dmg = math.max(1, math.floor(dmg * 0.5))
						end
						if typeof(last) ~= "number" or os.clock() - last > 0.75 then
							charH:SetAttribute("LastHazardAt", os.clock())
							applyDamage(player, dmg)
							local dy = child:GetAttribute("DisplaceY")
							if typeof(dy) == "number" then
								hrpH.AssemblyLinearVelocity = Vector3.new(hrpH.AssemblyLinearVelocity.X, dy, 0)
							end
						end
					end
				elseif hk == "conveyor" then
					local push = conveyorPushSigned(child)
					local v = hrpH.AssemblyLinearVelocity
					hrpH.AssemblyLinearVelocity = Vector3.new(v.X + push * 0.08, v.Y, 0)
					if not CombatService.HasIFrames(player) then
						local last = charH:GetAttribute("LastHazardAt")
						local dmg = (child:GetAttribute("HazardDamage") :: number?) or 4
						if typeof(last) ~= "number" or os.clock() - last > 0.9 then
							charH:SetAttribute("LastHazardAt", os.clock())
							applyDamage(player, dmg)
						end
					end
				elseif hk == "fireCone" and not CombatService.HasIFrames(player) then
					local last = charH:GetAttribute("LastHazardAt")
					if typeof(last) ~= "number" or os.clock() - last > 0.8 then
						charH:SetAttribute("LastHazardAt", os.clock())
						applyDamage(player, 4)
					end
				elseif hk == "hoaCone" and not CombatService.HasIFrames(player) then
					local last = charH:GetAttribute("LastHazardAt")
					local dmg = (child:GetAttribute("HazardDamage") :: number?) or Constants.HOA_CONE_DAMAGE
					if typeof(last) ~= "number" or os.clock() - last > 0.85 then
						charH:SetAttribute("LastHazardAt", os.clock())
						applyDamage(player, dmg)
					end
				elseif hk == "windPush" then
					local dir = (child:GetAttribute("WindDir") :: number?) or -1
					local spd = (child:GetAttribute("WindSpeed") :: number?) or Constants.WIND_PUSH_SPEED
					local v = hrpH.AssemblyLinearVelocity
					local vy = v.Y
					if child:GetAttribute("WindOpposeJump") == true and vy > 2 then
						vy = vy * Constants.WIND_OPPOSE_MULT
					end
					hrpH.AssemblyLinearVelocity = Vector3.new(dir * spd, vy, 0)
				end
			end
		elseif child:GetAttribute("JumpPad") then
			if math.abs(child.Position.X - hrpH.Position.X) < 3 and hrpH.Position.Y < child.Position.Y + 3 then
				onJumpPad = true
				local v = hrpH.AssemblyLinearVelocity
				local boost = (child:GetAttribute("PadBoost") :: number?) or 52
				if v.Y < 10 then
					hrpH.AssemblyLinearVelocity = Vector3.new(v.X, boost, 0)
				end
			end
		end
	end

	return inDeepWater, onJumpPad
end

local function applyWaterTimeout(
	player: Player,
	charH: Model,
	hrpH: BasePart,
	stH: HazardCtx,
	inDeepWater: boolean,
	onJumpPad: boolean,
	toast: ((Player, string) -> ())?
)
	-- N5 Act2: pad-only / soft-fall water timeout
	if onJumpPad or hrpH.Position.Y >= 2.8 then
		charH:SetAttribute("WaterSince", nil)
	elseif inDeepWater then
		local since = charH:GetAttribute("WaterSince")
		if typeof(since) ~= "number" then
			charH:SetAttribute("WaterSince", os.clock())
		elseif os.clock() - since >= Constants.WATER_TIMEOUT then
			triggerSoftFall(player, charH, hrpH, stH, toast, "Deep water — hit a pad next time.")
		end
	else
		charH:SetAttribute("WaterSince", nil)
	end
end

local function softFallAndLane(
	player: Player,
	char: Model,
	hrp: BasePart,
	st: HazardCtx,
	toast: ((Player, string) -> ())?
)
	local p = hrp.Position
	if math.abs(p.Z - Constants.LANE_Z) > 2.5 then
		hrp.CFrame = CFrame.new(p.X, p.Y, Constants.LANE_Z)
	end
	if st.runActive and st.stageIndex >= 1 then
		local stg = Stages.Get(st.stageId)
		if p.Y >= 1.5 and p.Y < 40 then
			char:SetAttribute("LastSolidX", p.X)
			char:SetAttribute("LastSolidY", math.max(3, p.Y))
			if stg and p.X > st.checkpointX + 4 then
				st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
			end
		elseif stg and p.X > st.checkpointX + 8 and p.Y >= 0 then
			st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
		end
		if p.Y < -2 then
			triggerSoftFall(player, char, hrp, st, toast, "Soft checkpoint — back on the lane.")
		end
		local worldT = Workspace:FindFirstChild("GameWorld")
		if worldT then
			for _, m in worldT:GetChildren() do
				if m:IsA("Model") and m:GetAttribute("IsAlly") and m:GetAttribute("EnemyId") == "RescueTurtle" and not m:GetAttribute("Rescued") then
					local root = m.PrimaryPart
					if root and not root:FindFirstChildOfClass("ProximityPrompt") then
						local pp = Instance.new("ProximityPrompt")
						pp.ActionText = "Rescue"
						pp.ObjectText = "Baby Turtle"
						pp.KeyboardKeyCode = Enum.KeyCode.E
						pp.HoldDuration = 0
						pp.ClickablePrompt = true
						pp.RequiresLineOfSight = false
						pp.MaxActivationDistance = 12
						pp:SetAttribute("FM_Action", "RescueTurtle")
						pp.Parent = root
					end
				end
			end
		end
	end
end

function HazardService.Tick(
	player: Player,
	ctx: HazardCtx,
	applyDamage: (Player, number) -> (),
	toast: ((Player, string) -> ())?
)
	local worldH = Workspace:FindFirstChild("GameWorld")
	local charH = player.Character
	local hrpH = charH and charH:FindFirstChild("HumanoidRootPart") :: BasePart?
	if worldH and hrpH and charH and ctx.runActive then
		local inWater, onPad = scanHazards(worldH, player, charH, hrpH, ctx, applyDamage, toast)
		applyWaterTimeout(player, charH, hrpH, ctx, inWater, onPad, toast)
	end
	if charH and hrpH then
		softFallAndLane(player, charH, hrpH, ctx, toast)
	end
end

return HazardService
