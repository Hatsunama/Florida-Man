--!strict
-- Publishes accepted movement state and procedural appearance to the character.
-- Derivation is owned by RunStats; cloud storage and command authorization stay elsewhere.
local Shared = game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local Personas = require(Shared:WaitForChild('Personas'))
local Weapons = require(Shared:WaitForChild('Weapons'))
local Types = require(Shared:WaitForChild('Types'))
local RunStats = require(script.Parent:WaitForChild('RunStats'))
local HazardRules = require(Shared:WaitForChild('HazardRules'))
type RunState = Types.RunState
local CharacterStatePublisher = {}
function CharacterStatePublisher.ApplyPersonaLook(player: Player, s: RunState?)
	local char = player.Character
	if not s or not char then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	if not persona then
		return
	end

    local lookKey = persona.id .. ':' .. s.weaponId
    if char:GetAttribute('AppliedLookKey') == lookKey then return end
    char:SetAttribute('AppliedLookKey',lookKey)
    char:SetAttribute("PersonaId", persona.id)
	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	if weapon then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponId", weapon.id)
		char:SetAttribute("WeaponKind", weapon.kind)
	end

	local bc: BodyColors = char:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
	bc.Parent = char
	local skin = persona.color:Lerp(Color3.fromRGB(255, 220, 180), 0.35)
	local accent = persona.accent
	bc.HeadColor3 = skin
	bc.TorsoColor3 = persona.color:Lerp(Color3.fromRGB(40, 40, 50), 0.25)
	bc.LeftArmColor3 = skin
	bc.RightArmColor3 = skin
	bc.LeftLegColor3 = accent:Lerp(skin, 0.5)
	bc.RightLegColor3 = accent:Lerp(skin, 0.5)

	local existing = char:FindFirstChild("FM_PersonaHighlight")
	local hl: Highlight = if existing and existing:IsA('Highlight') then existing else Instance.new('Highlight')
	hl.Name = 'FM_PersonaHighlight'
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = char
	do
		hl.FillColor = persona.color
		hl.OutlineColor = persona.accent
		hl.FillTransparency = 0.82
		hl.OutlineTransparency = 0.15
	end
end

function CharacterStatePublisher.ApplyCharacterSpeed(player: Player, s: RunState?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not s or not hum then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	local base = if persona then persona.moveSpeed else 18
	base += s.speedBonus

	-- N2: Hangover ≠ OilSlow — min-stack one mult, never multiply both blindly
	local hungover = os.clock() < s.hangoverUntil
	local oilUntil = if char then char:GetAttribute("OilSlowUntil") else nil
	local oiled = typeof(oilUntil) == "number" and os.clock() < oilUntil
	local environmentalUntil = if char then char:GetAttribute("EnvironmentalSlowUntil") else nil
	local environmental = typeof(environmentalUntil) == "number" and os.clock() < environmentalUntil
	local greasy = RunStats.HasGreasyOilResist(s)
	local mult = HazardRules.SlowMultiplier(hungover, oiled, environmental, greasy, Constants.HANGOVER_SLOW, Constants.OIL_SLOW_MULT, Constants.OIL_SLOW_MULT_RESIST)
	base *= mult
	s.moveSpeed = base

	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.AutoRotate = false
	if char then
		char:SetAttribute("MoveSpeed", base)
		char:SetAttribute("Hangover", hungover)
		char:SetAttribute("OilSlow", oiled)
		if not oiled then
			char:SetAttribute("OilSlowUntil", nil)
		end
		if not environmental then char:SetAttribute("EnvironmentalSlowUntil", nil) end
		char:SetAttribute("OilResist", greasy)
	end
	CharacterStatePublisher.ApplyPersonaLook(player,s)
end


return CharacterStatePublisher
