--!strict
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Weapons=require(Shared:WaitForChild("Weapons"))
local Equipment={}
local model: Model?=nil
local character: Model?=nil
local weaponId=""
local connections: { RBXScriptConnection }={}
local started=false
local function clear()
	if model then model:Destroy(); model=nil end
end
local function update()
	local char=character
	if not char or char~=Players.LocalPlayer.Character then return end
	local id=tostring(char:GetAttribute("WeaponId") or "BareHands")
	if id==weaponId and model and model.Parent then return end
	weaponId=id; clear()
	local def=Weapons.Get(id)
	if not def or id=="BareHands" then return end
	local hand=char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand or not hand:IsA("BasePart") then return end
	local kit=Instance.new("Model"); kit.Name="FM_HeldWeapon"; model=kit
	local part=Instance.new("Part")
	part.Name=def.name; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false; part.CastShadow=false; part.Massless=true
	part.Material=Enum.Material.SmoothPlastic
	part.Size=if def.kind=="ranged" then Vector3.new(0.6,0.6,1.6) elseif def.kind=="thrown" then Vector3.new(1.2,0.25,0.8) else Vector3.new(0.35,2.1,0.5)
	part.Color=if def.kind=="ranged" then Color3.fromRGB(135,190,190) elseif def.kind=="thrown" then Color3.fromRGB(224,164,88) else Color3.fromRGB(192,174,137)
	if def.vfx=="slap" or def.vfx=="board" or def.vfx=="bash" then part.Size=Vector3.new(0.9,1.5,0.22); part.Color=Color3.fromRGB(216,133,124) end
	part.CFrame=hand.CFrame*CFrame.new(0,-0.8,-0.15)
	part.Parent=kit
	local weld=Instance.new("WeldConstraint"); weld.Part0=hand; weld.Part1=part; weld.Parent=part
	kit.Parent=char
end
local function bind(char: Model)
	for _,connection in connections do connection:Disconnect() end
	table.clear(connections); clear(); character=char; weaponId=""
	table.insert(connections,char:GetAttributeChangedSignal("WeaponId"):Connect(update))
	table.insert(connections,char.ChildAdded:Connect(update))
	update()
end
function Equipment.Start()
	if started then return end
	started=true
	Players.LocalPlayer.CharacterAdded:Connect(bind)
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		for _,connection in connections do connection:Disconnect() end
		table.clear(connections); clear(); character=nil
	end)
	if Players.LocalPlayer.Character then bind(Players.LocalPlayer.Character) end
end
return Equipment
