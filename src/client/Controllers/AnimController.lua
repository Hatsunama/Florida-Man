--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Assets=require(Shared:WaitForChild("ArtAssets"))
local Settings=require(Shared:WaitForChild("Settings"))
local Anim={}
Anim.AnimationIds=Assets.AnimationIds
local persona="BeachBurnout"
local animator: Animator?=nil
local root: BasePart?=nil
local humanoid: Humanoid?=nil
local tracks: { [string]: AnimationTrack }={}
local attempted: { [string]: boolean }={}
local motors: { [string]: Motor6D }={}
local bases: { [Motor6D]: CFrame? }={}
local actionKind=""
local actionUntil=0
local actionStart=0
local proceduralAction=false
local freezeUntil=0
local freezeAt=0
local started=false
local character: Model?=nil
local characterConnections: { RBXScriptConnection }={}
local stockAnimate: LocalScript?=nil
local stockWasDisabled=false
local function restore()
	for motor,base in bases do if motor.Parent and base then motor.C0=base end end
end
local function clear()
	for _,track in tracks do track:Stop(0); track:Destroy() end
	table.clear(tracks); table.clear(attempted)
	restore()
	actionUntil=0; freezeUntil=0
end
local function getTrack(clip: string): AnimationTrack?
	if not animator then return nil end
	if tracks[clip] then return if tracks[clip].Length>0 then tracks[clip] else nil end
	if attempted[clip] then return nil end
	attempted[clip]=true
	local id=Assets.GetAnimationId(persona,clip)
	if not id then return nil end
	local animation=Instance.new("Animation")
	animation.AnimationId=id
	local ok,track=pcall(function() return (animator :: Animator):LoadAnimation(animation) end)
	animation:Destroy()
	if not ok or not track then return nil end
	track.Priority=if clip=="Idle" then Enum.AnimationPriority.Idle elseif clip=="Run" then Enum.AnimationPriority.Movement else Enum.AnimationPriority.Action
	track.Looped=clip=="Idle" or clip=="Run"
	tracks[clip]=track
	return if track.Length>0 then track else nil
end
local function stop(clip: string)
	local track=tracks[clip]
	if track and track.IsPlaying then track:Stop(0.1) end
end
local function action(clip: string,kind: string,duration: number)
	stop("Idle"); stop("Run")
	for key,track in tracks do if key~="Idle" and key~="Run" and track.IsPlaying then track:Stop(0.05) end end
	local track=getTrack(clip)
	proceduralAction=track==nil
	actionKind=kind
	actionStart=os.clock()
	actionUntil=actionStart+(if track then math.max(duration,track.Length) else duration)
	if track then track:Play(0.05) end
end
function Anim.SetPersona(id: string)
	if id==persona then return end
	clear(); persona=id
end
function Anim.PlayAttack(combo: number?)
	local index=math.clamp(combo or 1,1,3)
	action("Attack"..tostring(index),"attack",0.25)
end
function Anim.PlayDodge() action("Dodge","dodge",0.22) end
function Anim.PlayJump() action("Jump","jump",0.22) end
function Anim.PlaySkill() action("Skill","skill",0.35) end
function Anim.PlaySwap() action("Swap","swap",0.25) end
function Anim.Hitstop(duration: number)
	if Settings.IsReduceMotion(Players.LocalPlayer) then return end
	local now=os.clock()
	if now>=freezeUntil then freezeAt=now end
	freezeUntil=math.max(freezeUntil,now+math.clamp(duration,0,0.08))
end
local function teardown()
	for _,connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
	clear(); table.clear(motors); table.clear(bases)
	if stockAnimate and stockAnimate.Parent then stockAnimate.Disabled=stockWasDisabled end
	stockAnimate=nil; character=nil; root=nil; humanoid=nil; animator=nil
end
local ALIASES={RootJoint="Waist",["Right Shoulder"]="RightShoulder",["Left Shoulder"]="LeftShoulder",["Right Hip"]="RightHip",["Left Hip"]="LeftHip"}
local function bind(char: Model)
	if Players.LocalPlayer.Character~=char then return end
	teardown(); character=char
	local function refresh()
		if character~=char or Players.LocalPlayer.Character~=char then return end
		local hum=char:FindFirstChildOfClass("Humanoid")
		local hrp=char:FindFirstChild("HumanoidRootPart")
		if not char:IsDescendantOf(workspace) or not hum or not hrp or not hrp:IsA("BasePart") then root=nil; humanoid=nil; return end
		root=hrp; humanoid=hum
		-- Replicated Animator is the only track owner. A late Animator is adopted when it arrives.
		local owner=hum:FindFirstChildOfClass("Animator")
		if owner~=animator then clear(); animator=owner end
		local found: { [string]: Motor6D }={}
		for _,object in char:GetDescendants() do
			if object:IsA("Motor6D") then
				found[ALIASES[object.Name] or object.Name]=object
				if not bases[object] then bases[object]=object.C0 end
			end
		end
		motors=found
		for motor in bases do if not motor:IsDescendantOf(char) then bases[motor]=nil end end
		local animate=char:FindFirstChild("Animate")
		-- Claim stock animation only once a usable articulated fallback exists.
		if not stockAnimate and motors.RightShoulder and motors.LeftShoulder and motors.RightHip and motors.LeftHip and animate and animate:IsA("LocalScript") then
			stockAnimate=animate; stockWasDisabled=animate.Disabled; animate.Disabled=true
			if animator then for _,track in animator:GetPlayingAnimationTracks() do track:Stop(0) end end
		end
	end
	local scheduled=false
	local function schedule()
		if scheduled then return end
		scheduled=true
		task.defer(function() scheduled=false; refresh() end)
	end
	table.insert(characterConnections,char.DescendantAdded:Connect(schedule))
	table.insert(characterConnections,char.DescendantRemoving:Connect(schedule))
	table.insert(characterConnections,char.AncestryChanged:Connect(schedule))
	refresh()
end
local POSES={
	BeachBurnout={twist=22,arm=70,spread=30},
	CrabKing={twist=-28,arm=42,spread=62},
	GatorHauler={twist=12,arm=100,spread=28},
	SnakeCharmer={twist=-18,arm=48,spread=44},
	GolfCartBandit={twist=30,arm=82,spread=12},
	FireworksEnthusiast={twist=10,arm=115,spread=55},
	LizardBreath={twist=-12,arm=62,spread=40},
	TurtlePaladin={twist=4,arm=75,spread=18},
}
local function offset(name: string,cf: CFrame)
	local motor=motors[name]
	local base=if motor then bases[motor] else nil
	if motor and motor.Parent and base then motor.C0=base*cf end
end
function Anim.Start()
	if started then return end
	started=true
	Players.LocalPlayer.CharacterAdded:Connect(bind)
	Players.LocalPlayer.CharacterRemoving:Connect(function(char) if character==char then teardown() end end)
	if Players.LocalPlayer.Character then task.defer(bind,Players.LocalPlayer.Character) end
	RunService.RenderStepped:Connect(function()
		if not root or not root.Parent or not humanoid then return end
		local id=root.Parent:GetAttribute("PersonaId")
		if typeof(id)=="string" and id~=persona then Anim.SetPersona(id) end
		local now=os.clock()
		local frozen=now<freezeUntil
		for _,track in tracks do if track.IsPlaying then track:AdjustSpeed(if frozen then 0 else 1) end end
		restore()
		local moving=math.abs(root.AssemblyLinearVelocity.X)>2
		local airborne=humanoid.FloorMaterial==Enum.Material.Air
		local locomotionFallback=false
		if now>=actionUntil then
			proceduralAction=false
			if airborne then stop("Idle"); stop("Run"); locomotionFallback=true
			else
				local wanted=if moving then "Run" else "Idle"
				stop(if moving then "Idle" else "Run")
				local track=getTrack(wanted)
				if track and not track.IsPlaying then track:Play(0.15) end
				locomotionFallback=track==nil
			end
		end
		local scale=if Settings.IsReduceMotion(Players.LocalPlayer) then 0.25 else 1
		if locomotionFallback then
			if airborne then
				local rising=root.AssemblyLinearVelocity.Y>2
				offset("RightHip",CFrame.Angles(math.rad(if rising then -24 else 12),0,0))
				offset("LeftHip",CFrame.Angles(math.rad(if rising then 18 else -12),0,0))
				offset("RightShoulder",CFrame.Angles(0,0,math.rad(18*scale)))
				offset("LeftShoulder",CFrame.Angles(0,0,math.rad(-18*scale)))
			elseif moving then
				local cycle=(if frozen then freezeAt else now)*math.clamp(math.abs(root.AssemblyLinearVelocity.X)*0.65,7,18)
				local stride=math.sin(cycle)*math.rad(32)*math.max(0.55,scale)
				offset("RightHip",CFrame.Angles(stride,0,0)); offset("LeftHip",CFrame.Angles(-stride,0,0))
				offset("RightShoulder",CFrame.Angles(-stride*0.65,0,0)); offset("LeftShoulder",CFrame.Angles(stride*0.65,0,0))
			else
				local breathe=math.sin((if frozen then freezeAt else now)*2)*math.rad(1.5)*scale
				offset("Waist",CFrame.Angles(breathe,0,0))
			end
		end
		if proceduralAction and now<actionUntil then
			local pose=POSES[persona] or POSES.BeachBurnout
			local t=math.clamp(((if frozen then freezeAt else now)-actionStart)/math.max(0.01,actionUntil-actionStart),0,1)
			local amount=math.sin(t*math.pi)*scale
			if actionKind=="attack" or actionKind=="skill" then
				offset("Waist",CFrame.Angles(0,math.rad(pose.twist*amount),0))
				offset("RightShoulder",CFrame.Angles(math.rad(-pose.arm*amount),0,math.rad(pose.spread*amount)))
				offset("LeftShoulder",CFrame.Angles(math.rad(-pose.arm*0.6*amount),0,math.rad(-pose.spread*amount)))
			elseif actionKind=="dodge" then offset("Waist",CFrame.Angles(math.rad(-20*amount),0,0))
			elseif actionKind=="swap" then offset("Waist",CFrame.Angles(0,math.rad(35*amount),0))
			elseif actionKind=="jump" then
				offset("RightShoulder",CFrame.Angles(math.rad(-30*amount),0,0))
				offset("LeftShoulder",CFrame.Angles(math.rad(-30*amount),0,0))
			end
		end
	end)
end
return Anim
