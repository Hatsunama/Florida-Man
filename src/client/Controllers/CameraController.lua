--!strict
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants=require(Shared:WaitForChild("Constants"))
local Settings=require(Shared:WaitForChild("Settings"))
local Camera={}
local focus: Vector3?=nil
local focusUntil=0
local arena: Vector3?=nil
local center: Vector3?=nil
local shake=0
local shakeUntil=0
local started=false
local stageLength=240
local previousRoot: Vector3?=nil
local motionRevision: any=nil
local function spring(current: number,target: number,dt: number): number
	return target+(current-target)*math.exp(-9*math.clamp(dt,0,0.25))
end
function Camera.Reset(length: number?)
	center=nil; arena=nil; focus=nil; focusUntil=0; shake=0; shakeUntil=0; previousRoot=nil
	if typeof(length)=="number" then stageLength=length end
end
function Camera.Shake(amount: number,duration: number?)
	if Settings.IsReduceMotion(Players.LocalPlayer) or not Settings.GetBool(Players.LocalPlayer,"ShakeEnabled") then return end
	shake=math.max(shake,math.clamp(amount,0,0.75))
	shakeUntil=os.clock()+(duration or 0.15)
end
function Camera.Focus(position: Vector3,duration: number?)
	if Settings.IsReduceMotion(Players.LocalPlayer) then return end
	focus=position; focusUntil=os.clock()+math.clamp(duration or 0.35,0.1,0.45)
end
function Camera.LockArena(position: Vector3) arena=position end
function Camera.UnlockArena(position: Vector3?) arena=nil; if position then Camera.Focus(position) end end
function Camera.Start()
	if started then return end
	started=true
	Players.LocalPlayer.CharacterAdded:Connect(function() Camera.Reset() end)
	RunService:BindToRenderStep("FM_Camera",Enum.RenderPriority.Camera.Value+1,function(dt)
		local camera=workspace.CurrentCamera
		local char=Players.LocalPlayer.Character
		local root=char and char:FindFirstChild("HumanoidRootPart")
		if not camera or not char or not root or not root:IsA("BasePart") then return end
		camera.CameraType=Enum.CameraType.Scriptable
		local pos=root.Position
		local reset=char:GetAttribute("MotionResetRevision")
		if reset~=motionRevision then center=nil; arena=nil; focus=nil; motionRevision=reset end
		if previousRoot and (pos-previousRoot).Magnitude>45 then center=nil; arena=nil; focus=nil end
		previousRoot=pos
		if not center then center=pos end
		local target=pos
		if arena and not Settings.IsReduceMotion(Players.LocalPlayer) then
			target=Vector3.new(math.clamp(arena.X,pos.X-7,pos.X+7),pos.Y,pos.Z)
		end
		if focus and os.clock()<focusUntil then target=target:Lerp(Vector3.new(math.clamp(focus.X,pos.X-8,pos.X+8),pos.Y,pos.Z),0.25) end
		local c=center :: Vector3
		local delta=target.X-c.X
		local tx=if math.abs(delta)>2.5 then target.X-math.sign(delta)*2.5 else c.X
		local x=spring(c.X,tx,dt)
		local y=spring(c.Y,target.Y,dt)
		-- Bounded lag and translation-invariant relative deadzone.
		x=math.clamp(x,pos.X-6,pos.X+6)
		center=Vector3.new(x,y,Constants.LANE_Z)
		local look=Vector3.new(math.clamp(x+5,-2,stageLength+8),y+2,Constants.LANE_Z)
		local offset=Vector3.zero
		if os.clock()<shakeUntil and not Settings.IsReduceMotion(Players.LocalPlayer) then
			offset=Vector3.new(math.noise(os.clock()*32,1),math.noise(os.clock()*32,2),0)*shake
			shake*=math.exp(-10*math.clamp(dt,0,0.25))
		end
		camera.CFrame=CFrame.new(look+Vector3.new(-2,7,Constants.CAMERA_DEPTH or 32)+offset,look+offset)
		camera.FieldOfView=65
	end)
end
Camera.StepScalar=spring
return Camera
