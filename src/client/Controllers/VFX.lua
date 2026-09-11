--!strict
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local Players=game:GetService("Players")
local Settings=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Settings"))
local VFX={}
local COLORS={
	punch=Color3.fromRGB(255,218,130),slap=Color3.fromRGB(255,137,170),grab=Color3.fromRGB(126,202,129),
	foam=Color3.fromRGB(222,247,248),net=Color3.fromRGB(152,213,137),firework=Color3.fromRGB(255,135,135),
	dart=Color3.fromRGB(228,232,142),cone=Color3.fromRGB(255,164,81),hose=Color3.fromRGB(138,125,83),
	balloon=Color3.fromRGB(139,204,244),disc=Color3.fromRGB(162,194,213),rocket=Color3.fromRGB(255,183,85),
}
local function effect(name: string,position: Vector3,size: Vector3,color: Color3,finish: Vector3?,shape: Enum.PartType?): Part
	local part=Instance.new("Part")
	part.Name=name; part.Anchored=true; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false
	part.CastShadow=false; part.Material=Enum.Material.SmoothPlastic
	part.Color=color; part.Size=size; part.Position=position; part.Transparency=0.3
	part.Shape=shape or Enum.PartType.Block
	part.Parent=workspace
	local reduced=Settings.IsReduceMotion(Players.LocalPlayer)
	local target={Transparency=1}
	if not reduced and finish then (target :: any).Position=finish end
	TweenService:Create(part,TweenInfo.new(if reduced then 0.12 else 0.22),target):Play()
	Debris:AddItem(part,0.3)
	return part
end
function VFX.SwingSlash(root: BasePart,facing: number,combo: number?,kind: string?)
	local key=kind or "punch"
	local color=COLORS[key] or Color3.fromRGB(244,211,136)
	local ranged=table.find({"foam","net","firework","hose","balloon"},key)~=nil
	local thrown=table.find({"dart","cone","disc","rocket","lasso"},key)~=nil
	local size=if ranged then Vector3.new(4,0.25,0.4) elseif thrown then Vector3.new(1.5,0.3,0.6) else Vector3.new(3,0.3,1.4)
	if Settings.IsReduceMotion(Players.LocalPlayer) then size=Vector3.new(1,0.25,0.6) end
	local pos=root.Position+Vector3.new(facing*3.4,0.8,0)
	local part=effect("FM_ActionCue",pos,size,color,pos+Vector3.new(facing*(if ranged then 5 else 2),if thrown then 1.5 else 0,0),if key=="punch" then Enum.PartType.Ball else nil)
	part.CFrame*=CFrame.Angles(0,0,if ranged then 0 else math.rad(facing*(12+(combo or 1)*7)))
end
function VFX.HitSpark(pos: Vector3,heavy: boolean?)
	if Settings.GetBool(Players.LocalPlayer,"ReduceFlashes") or Settings.IsReduceMotion(Players.LocalPlayer) then return end
	effect("FM_Hit",pos,Vector3.one*(if heavy then 1.4 else 0.9),Color3.fromRGB(250,219,153),nil,Enum.PartType.Ball)
end
function VFX.SwapBurst(root: BasePart,color: Color3)
	if Settings.IsReduceMotion(Players.LocalPlayer) then return end
	effect("FM_Swap",root.Position,Vector3.new(3,0.25,3),color,nil)
end
function VFX.SkillPattern(root: BasePart,kind: string,facing: number)
	local pos=root.Position+Vector3.new(facing*3,0.5,0)
	local size=if kind=="beam" or kind=="wave" then Vector3.new(12,0.5,1) elseif kind=="shield" then Vector3.new(3,3,3) else Vector3.new(5,0.3,3)
	if Settings.IsReduceMotion(Players.LocalPlayer) then size=Vector3.new(1.5,0.25,1) end
	effect("FM_Skill",pos,size,Color3.fromRGB(150,213,192),nil,if kind=="shield" then Enum.PartType.Ball else nil)
end
function VFX.WaterRipple(pos: Vector3)
	if not Settings.IsReduceMotion(Players.LocalPlayer) then effect("FM_Ripple",pos,Vector3.new(2,0.1,2),Color3.fromRGB(150,206,223),nil) end
end
return VFX
