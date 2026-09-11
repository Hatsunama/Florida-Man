--!strict
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings=require(Shared:WaitForChild("Settings"))
local Definitions=require(Shared:WaitForChild("HazardDefinitions"))
local Rules=require(script.Parent:WaitForChild("AccessibilityRules"))
local Accessibility={}
local player=Players.LocalPlayer
local started=false
type Marker={folder: Folder?,cue: string?,direction: number,connections: {RBXScriptConnection}}
local markers: { [BasePart]: Marker? }={}
local particles: { [ParticleEmitter]: number? }={}
local function style(part: BasePart,record: Marker)
	local id=part:GetAttribute("Hazard")
	local definition=if typeof(id)=="string" then Definitions[id] else nil
	local cue=if Settings.GetBool(player,"ColorblindTelegraphs") then Rules.Cue(definition,part:GetAttribute("HazardEnabled")~=false,part:GetAttribute("HazardActive")~=false,part:GetAttribute("AttackVolume")==true or part.Name=="Telegraph") else nil
	local rawDirection=part:GetAttribute("ConveyorDir") or part:GetAttribute("WindDir") or 1
	local direction=if typeof(rawDirection)=="number" and rawDirection<0 then -1 else 1
	if record.cue==cue and record.direction==direction then return end
	if record.folder then record.folder:Destroy(); record.folder=nil end
	record.cue=cue; record.direction=direction
	if not cue or not part.Parent then return end
	local folder=Instance.new("Folder"); folder.Name="FM_LocalHazardPattern"; folder.Parent=part; record.folder=folder
	-- Surface-only patterns never obstruct actors with another floating text label.
	local surface=Instance.new("SurfaceGui")
	surface.Name="HazardPattern"; surface.Adornee=part; surface.Face=Enum.NormalId.Top
	surface.CanvasSize=Vector2.new(240,160); surface.AlwaysOnTop=false; surface.LightInfluence=0; surface.Parent=folder
	if cue=="flow" then
		local arrow=Instance.new("TextLabel"); arrow.Size=UDim2.fromScale(1,1); arrow.BackgroundTransparency=1
		arrow.Text=if direction<0 then "‹ ‹ ‹" else "› › ›"; arrow.TextSize=64; arrow.Font=Enum.Font.GothamBold
		arrow.TextColor3=Color3.fromRGB(225,244,250); arrow.Parent=surface
	else
		for index=0,5 do
			local mark=Instance.new("Frame"); mark.BorderSizePixel=0
			mark.Position=UDim2.fromScale(index/6,if cue=="slow" then 0.35 else 0)
			mark.Size=UDim2.fromScale(if cue=="slow" then 0.07 else 0.035,if cue=="slow" then 0.25 else 1)
			mark.BackgroundColor3=if cue=="danger" then Color3.fromRGB(255,248,199) else Color3.fromRGB(220,242,250)
			mark.BackgroundTransparency=0.18; mark.Parent=surface
		end
	end
end
local function remove(object: Instance)
	if object:IsA("BasePart") then
		local record=markers[object]
		if record then
			for _,connection in record.connections do connection:Disconnect() end
			if record.folder then record.folder:Destroy() end
			markers[object]=nil
		end
	elseif object:IsA("ParticleEmitter") then
		local original=particles[object]
		if original~=nil then object.LocalTransparencyModifier=original; particles[object]=nil end
	end
end
local function inspect(object: Instance)
	if not object:IsDescendantOf(workspace) then return end
	if object:IsA("ParticleEmitter") then
		local original: number=particles[object] or object.LocalTransparencyModifier
		particles[object]=original
		-- Local visibility preserves server Enabled/Emit state, including changes after this setting is applied.
		object.LocalTransparencyModifier=if Settings.IsReduceMotion(player) then 1 else original
	elseif object:IsA("BasePart") and (object:GetAttribute("AttackVolume")==true or object.Name=="Telegraph" or object:GetAttribute("Hazard")~=nil) then
		local existing=markers[object]
		if existing then style(object,existing); return end
		local record: Marker={folder=nil,cue=nil,direction=0,connections={}}
		markers[object]=record
		table.insert(record.connections,object.AttributeChanged:Connect(function(key)
			if key=="Hazard" or key=="HazardEnabled" or key=="HazardActive" or key=="AttackVolume" or key=="ConveyorDir" or key=="WindDir" then style(object,record) end
		end))
		style(object,record)
	end
end
function Accessibility.Start()
	if started then return end
	started=true
	workspace.DescendantAdded:Connect(function(object) task.defer(inspect,object) end)
	workspace.DescendantRemoving:Connect(remove)
	local function refresh() for _,object in workspace:GetDescendants() do inspect(object) end end
	player:GetAttributeChangedSignal("ColorblindTelegraphs"):Connect(refresh)
	player:GetAttributeChangedSignal("ReduceMotion"):Connect(refresh)
	refresh()
end
return Accessibility
