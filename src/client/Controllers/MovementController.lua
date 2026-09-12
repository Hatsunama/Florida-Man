--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants=require(Shared:WaitForChild("Constants"))
local CharacterGeometry=require(Shared:WaitForChild("CharacterGeometry"))
local Anim=require(script.Parent:WaitForChild("AnimController"))
local Movement={}
local player=Players.LocalPlayer
local root: BasePart?=nil
local humanoid: Humanoid?=nil
local lane: AlignPosition?=nil
local orientation: AlignOrientation?=nil
local attachment: Attachment?=nil
local enabled=true
local axis=0
local baseSpeed=18
local facing=1
local velocity=0
local jumpHeld=false
local jumpBuffer=0
local coyote=0
local jumping=false
local dodgeRemaining=0
local dodgeDirection=1
local lockUntil=0
local impulseRevision: any=nil
local resetRevision: any=nil
local previousExternalY=0
local started=false
local character: Model?=nil
local characterConnections: { RBXScriptConnection }={}
local params=RaycastParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.RespectCanCollide=true
local JUMP_SPEED=54
local function face(): CFrame return CFrame.lookAlong(Vector3.zero,Vector3.new(facing,0,0)) end
local function teardown()
	if lane then lane:Destroy() end
	if orientation then orientation:Destroy() end
	if attachment then attachment:Destroy() end
	lane=nil; orientation=nil; attachment=nil; root=nil; humanoid=nil
end
function Movement.Reset()
	axis=0; velocity=0; jumpHeld=false; jumpBuffer=0; coyote=0; jumping=false; dodgeRemaining=0; lockUntil=0; impulseRevision=nil; previousExternalY=0
	local char=root and root.Parent
	if char then impulseRevision=char:GetAttribute("ImpulseRevision"); resetRevision=char:GetAttribute("MotionResetRevision") end
end
local function bind(char: Model)
	if player.Character~=char then return end
	for _,connection in characterConnections do connection:Disconnect() end
	table.clear(characterConnections)
	teardown(); Movement.Reset()
	character=char
	local function refresh()
	if character~=char or player.Character~=char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart")
	local hum=char:FindFirstChildOfClass("Humanoid")
	if not char:IsDescendantOf(workspace) or not hrp or not hrp:IsA("BasePart") or not hum then teardown(); return end
	if root==hrp and humanoid==hum then return end
	teardown(); Movement.Reset()
	root=hrp; humanoid=hum
	hum.AutoRotate=false; hum.WalkSpeed=0; hum.JumpPower=0; hum.JumpHeight=0
	params.FilterDescendantsInstances={char}
	local moveAttachment=Instance.new("Attachment")
	moveAttachment.Name="FM_MoveAttach"; moveAttachment.Parent=hrp; attachment=moveAttachment
	local laneLock=Instance.new("AlignPosition")
	laneLock.Name="FM_LaneLock"; laneLock.Mode=Enum.PositionAlignmentMode.OneAttachment; laneLock.Attachment0=moveAttachment
	laneLock.ApplyAtCenterOfMass=true; laneLock.Responsiveness=55; laneLock.MaxForce=1e6
	laneLock.ForceLimitMode=Enum.ForceLimitMode.PerAxis; laneLock.MaxAxesForce=Vector3.new(0,0,250000)
	laneLock.Position=Vector3.new(hrp.Position.X,hrp.Position.Y,Constants.LANE_Z); laneLock.Parent=hrp; lane=laneLock
	local faceLock=Instance.new("AlignOrientation")
	faceLock.Name="FM_Face"; faceLock.Mode=Enum.OrientationAlignmentMode.OneAttachment; faceLock.Attachment0=moveAttachment
	faceLock.RigidityEnabled=true; faceLock.MaxTorque=1e7; faceLock.CFrame=face(); faceLock.Parent=hrp; orientation=faceLock
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
function Movement.SetMoveAxis(value: number) axis=math.clamp(value,-1,1) end
function Movement.SetBaseSpeed(value: number) if value==value and value>0 and value<250 then baseSpeed=value end end
function Movement.SetEnabled(value: boolean)
	if enabled and not value then velocity=0; dodgeRemaining=0 end
	enabled=value
	if not value then axis=0; jumpHeld=false; jumpBuffer=0 end
end
function Movement.SetJumpHeld(value: boolean)
	if value and not jumpHeld and enabled then jumpBuffer=0.12 end
	if not value and jumpHeld and jumping and root and root.AssemblyLinearVelocity.Y>0 then
		local v=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(v.X,v.Y*0.48,v.Z)
	end
	jumpHeld=value
end
function Movement.GetFacing(): number return facing end
function Movement.LockFacing(value: number,duration: number)
	facing=if value>=0 then 1 else -1
	lockUntil=os.clock()+duration
end
-- Hitstop is visual-only: animation freeze never changes simulation or a11y physics.
function Movement.Hitstop(duration: number?) Anim.Hitstop(duration or Constants.HITSTOP) end
function Movement.ApplyDodge(direction: number): boolean
	if not enabled or not root then return false end
	facing=if direction==-1 then -1 else 1
	dodgeDirection=facing
	dodgeRemaining=Constants.DODGE_DURATION
	Anim.PlayDodge()
	return true
end
function Movement.CancelDodge()
	dodgeRemaining=0
	velocity=axis*baseSpeed
end
function Movement.Start()
	if started then return end
	started=true
	player.CharacterAdded:Connect(bind)
	player.CharacterRemoving:Connect(function(char)
		if character~=char then return end
		character=nil
		for _,connection in characterConnections do connection:Disconnect() end
		table.clear(characterConnections); teardown(); Movement.Reset()
	end)
	if player.Character then task.defer(bind,player.Character) end
	RunService.PreSimulation:Connect(function(dt)
		if not root or not humanoid or not root.Parent or humanoid.Health<=0 then return end
		dt=math.clamp(dt,0,0.1)
		local char=root.Parent
		local reset=char:GetAttribute("MotionResetRevision")
		if reset~=resetRevision then
			Movement.Reset(); resetRevision=reset
			impulseRevision=char:GetAttribute("ImpulseRevision")
		end
		local speed=char:GetAttribute("MoveSpeed")
		if typeof(speed)=="number" then Movement.SetBaseSpeed(speed) end
		local v=root.AssemblyLinearVelocity
		local hit=workspace:Raycast(root.Position,Vector3.new(0,-(CharacterGeometry.FeetDistance(char :: Model,root,humanoid)+0.45),0),params)
		local grounded=hit~=nil and hit.Normal.Y>0.65 and v.Y<4
		if grounded then coyote=0.12; jumping=false else coyote=math.max(0,coyote-dt) end
		jumpBuffer=math.max(0,jumpBuffer-dt)
		local vy=v.Y-previousExternalY
		if enabled and jumpBuffer>0 and coyote>0 then
			vy=JUMP_SPEED; jumpBuffer=0; coyote=0; jumping=true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			Anim.PlayJump()
		end
		local desired=if enabled then axis*baseSpeed else 0
		local activeDt=if enabled then math.min(dt,dodgeRemaining) else 0
		local dodging=activeDt>0 and dt>0
		if dodging then
			local fraction=activeDt/dt
			desired=dodgeDirection*(Constants.DODGE_DISTANCE/Constants.DODGE_DURATION)*fraction+axis*baseSpeed*(1-fraction)
		end
		dodgeRemaining=math.max(0,dodgeRemaining-dt)
		local acceleration=if grounded then 180 else 110
		if dodging then velocity=desired else velocity+=math.clamp(desired-velocity,-acceleration*dt,acceleration*dt) end
		if math.abs(axis)>0.1 and os.clock()>lockUntil then facing=if axis>0 then 1 else -1 end
		local motionUntil=char:GetAttribute("ExternalMotionUntil")
		local externalX=0
		local externalY=0
		if typeof(motionUntil)=="number" and workspace:GetServerTimeNow()<motionUntil then
			local x=char:GetAttribute("ExternalVelocityX")
			local y=char:GetAttribute("ExternalVelocityY")
			externalX=if typeof(x)=="number" then x else 0
			externalY=if typeof(y)=="number" then y else 0
		end
		local revision=char:GetAttribute("ImpulseRevision")
		if revision~=nil and revision~=impulseRevision then
			impulseRevision=revision
			local y=char:GetAttribute("ImpulseY")
			if typeof(y)=="number" then vy=math.max(vy,y) end
		end
		local targetX=velocity+externalX
		-- Sweep grounded horizontal bursts against collidable gates and walls.
		if math.abs(targetX)>baseSpeed+1 then
			local delta=Vector3.new(targetX*dt,0,0)
			local obstacle=workspace:Raycast(root.Position,delta+Vector3.new(math.sign(targetX)*1.2,0,0),params)
			if obstacle then targetX=0; velocity=0; dodgeRemaining=0 end
		end
		root.AssemblyLinearVelocity=Vector3.new(targetX,vy+externalY,0)
		if dodging and dodgeRemaining<=0 then velocity=axis*baseSpeed end
		previousExternalY=externalY
		if lane then lane.Position=Vector3.new(root.Position.X,root.Position.Y,Constants.LANE_Z) end
		if orientation then orientation.CFrame=face() end
		humanoid:Move(Vector3.new(if enabled then axis else 0,0,0),false)
		char:SetAttribute("Facing",facing)
	end)
end
return Movement
