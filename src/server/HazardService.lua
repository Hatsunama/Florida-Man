--!strict
--[[ Phase 6 — hazard / world tick helpers extracted from GameService.

	Owns: timed hazard duty cycle, oil/water slow, fryer/slush/pipe damage,
	conveyor push, wind, jump pads, checkpoint markers, soft-fall respawn,
	turtle ProximityPrompt re-attach.
]]

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

local function tickTimedHazard(part: BasePart): boolean
	local period = part:GetAttribute("HazardPeriod")
	if typeof(period) ~= "number" or period <= 0 then
		return true -- always active
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

local function scanHazards(
	container: Instance,
	player: Player,
	charH: Model,
	hrpH: BasePart,
	stH: HazardCtx,
	applyDamage: (Player, number) -> ()
)
	for _, child in container:GetChildren() do
		if child:IsA("Folder") then
			scanHazards(child, player, charH, hrpH, stH, applyDamage)
			continue
		end
		if not child:IsA("BasePart") then
			continue
		end
		-- Moving lab samples
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
			local reach = if hk == "conveyor" then 6 elseif hk == "pipeSpray" then 4.5 else 5
			if (child.Position - hrpH.Position).Magnitude < reach then
				if hk == "canalWater" or child:GetAttribute("WaterSlow") then
					local slow = (child:GetAttribute("SlowAmount") :: number?) or 7
					stH.moveSpeed = math.min(stH.moveSpeed, slow)
					charH:SetAttribute("MoveSpeed", stH.moveSpeed)
					charH:SetAttribute("OilSlow", true)
					task.delay(0.9, function()
						if charH then
							charH:SetAttribute("OilSlow", nil)
						end
					end)
				elseif hk == "oilSlick" or hk == "sandSlow" or hk == "redTide" then
					stH.moveSpeed = math.min(stH.moveSpeed, 12)
					charH:SetAttribute("MoveSpeed", stH.moveSpeed)
					charH:SetAttribute("OilSlow", true)
					task.delay(1.2, function()
						if charH then
							charH:SetAttribute("OilSlow", nil)
						end
					end)
				elseif (hk == "fryerOil" or hk == "slushPuddle" or hk == "pipeSpray" or hk == "slickRing" or hk == "movingSample") and active then
					if not CombatService.HasIFrames(player) and hrpH.Position.Y < child.Position.Y + 3.5 then
						local last = charH:GetAttribute("LastHazardAt")
						local dmg = (child:GetAttribute("HazardDamage") :: number?) or 5
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
					local push = (child:GetAttribute("ConveyorPush") :: number?) or 18
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
				elseif hk == "windPush" then
					local dir = (child:GetAttribute("WindDir") :: number?) or -1
					hrpH.AssemblyLinearVelocity = Vector3.new(dir * 18, hrpH.AssemblyLinearVelocity.Y, 0)
				end
			end
		elseif child:GetAttribute("JumpPad") then
			if math.abs(child.Position.X - hrpH.Position.X) < 3 and hrpH.Position.Y < child.Position.Y + 3 then
				local v = hrpH.AssemblyLinearVelocity
				local boost = (child:GetAttribute("PadBoost") :: number?) or 52
				if v.Y < 10 then
					hrpH.AssemblyLinearVelocity = Vector3.new(v.X, boost, 0)
				end
			end
		end
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
		if stg and p.X > st.checkpointX + 8 then
			st.checkpointX = math.max(st.checkpointX, math.min(p.X, stg.length - 15))
		end
		if p.Y < -2 then
			local lastFall = char:GetAttribute("LastSoftFallAt")
			if typeof(lastFall) ~= "number" or os.clock() - lastFall > 1.0 then
				char:SetAttribute("LastSoftFallAt", os.clock())
				local cx = st.checkpointX or Constants.SPAWN_X
				if typeof(cx) ~= "number" or cx < Constants.SPAWN_X then
					cx = Constants.SPAWN_X
				end
				hrp.CFrame = CFrame.new(cx, 5, Constants.LANE_Z)
				hrp.AssemblyLinearVelocity = Vector3.zero
				if toast then
					toast(player, "Soft checkpoint — back on the lane.")
				end
				Remotes.Get("CombatEvent"):FireClient(player, { kind = "shake", amount = 0.4 })
				Remotes.Get("PlaySound"):FireClient(player, "SFX_Splash")
			end
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

--[[ Tick hazards + soft-fall for one player. Mutates ctx.checkpointX / moveSpeed. ]]
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
		scanHazards(worldH, player, charH, hrpH, ctx, applyDamage)
	end
	if charH and hrpH then
		softFallAndLane(player, charH, hrpH, ctx, toast)
	end
end

return HazardService
