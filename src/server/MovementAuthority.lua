--!strict
-- The movement trust boundary. No dependency on gameplay, enemies, or hazards:
-- approved server actions issue finite grants; all positional consumers validate.
local Players=game:GetService('Players')
local Workspace=game:GetService('Workspace')
local Shared=game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Constants=require(Shared:WaitForChild('Constants'))
local Envelope=require(Shared:WaitForChild('MovementEnvelope'))
local CharacterGeometry=require(Shared:WaitForChild('CharacterGeometry'))
local Authority={}
type Record={character: Model, motion: Envelope.State, safe: Vector3, externalX: number, externalUntil: number}
local records: {[Player]: Record}={}

local function params(): RaycastParams
	local ignored: {Instance}={}
	for _,player in Players:GetPlayers() do if player.Character then table.insert(ignored,player.Character) end end
	local world=Workspace:FindFirstChild('GameWorld')
	if world then for _,child in world:GetChildren() do
		if child:IsA('Model') and child:GetAttribute('EnemyId') then table.insert(ignored,child) end
	end end
	local result=RaycastParams.new()
	result.FilterType=Enum.RaycastFilterType.Exclude; result.FilterDescendantsInstances=ignored
	result.RespectCanCollide=true; result.IgnoreWater=true
	return result
end

local function grounded(root: BasePart, hum: Humanoid, casts: RaycastParams): boolean
	local support=Workspace:Raycast(root.Position,Vector3.new(0,-(CharacterGeometry.FeetDistance(hum.Parent :: Model,root,hum)+0.45),0),casts)
	return support~=nil and support.Normal.Y>0.65
end

local function notifyCorrection(char: Model)
	char:SetAttribute('MotionResetRevision',((char:GetAttribute('MotionResetRevision') :: number?) or 0)+1)
end

function Authority.Reset(player: Player, destination: CFrame)
	local char=player.Character
	local root=char and char:FindFirstChild('HumanoidRootPart')
	local hum=char and char:FindFirstChildOfClass('Humanoid')
	if not char or not root or not root:IsA('BasePart') or not hum then records[player]=nil; return end
	-- This exact destination is recorded immediately; there is no future window
	-- in which an arbitrary client coordinate can become the new baseline.
	root.CFrame=destination; root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
	local p=destination.Position
	records[player]={character=char,motion=Envelope.New(p.X,p.Y,p.Z,os.clock(),grounded(root,hum,params())),
		safe=p,externalX=0,externalUntil=0}
	char:SetAttribute('AuthorizedTeleportUntil',nil)
	notifyCorrection(char)
end

function Authority.AllowDodge(player: Player, distance: number, duration: number)
	local r=records[player]
	if not r or r.character~=player.Character then return end
	local speed=(r.character:GetAttribute('MoveSpeed') :: number?) or 18
	Envelope.AllowDodge(r.motion,os.clock(),distance,duration,speed)
end

function Authority.AllowImpulse(player: Player, velocityY: number)
	local r=records[player]
	if r and r.character==player.Character then Envelope.AllowImpulse(r.motion,os.clock(),velocityY) end
end

function Authority.SetExternal(player: Player, velocityX: number, _velocityY: number, duration: number)
	local r=records[player]
	if r then r.externalX=math.clamp(velocityX,-18,18); r.externalUntil=os.clock()+duration end
end

function Authority.Validate(player: Player): boolean
	local char=player.Character
	local root=char and char:FindFirstChild('HumanoidRootPart')
	local hum=char and char:FindFirstChildOfClass('Humanoid')
	local world=Workspace:FindFirstChild('GameWorld')
	if not char or not root or not root:IsA('BasePart') or not hum or hum.Health<=0 or not world then return false end
	local r=records[player]
	if not r or r.character~=char then
		Authority.Reset(player,CFrame.new(Constants.SPAWN_X,5,Constants.LANE_Z))
		return false
	end
	local now=os.clock()
	local p=root.Position
	local length=(world:GetAttribute('StageLength') :: number?) or 1000
	local bounds=p.X==p.X and p.Y==p.Y and p.Z==p.Z and p.X>=-6 and p.X<=length+6 and p.Y>=-8 and p.Y<=65 and math.abs(p.Z-Constants.LANE_Z)<=3
	local casts=params()
	local previous=Vector3.new(r.motion.x,r.motion.y,r.motion.z)
	local delta=p-previous
	local clear=bounds and (delta.Magnitude<0.01 or Workspace:Raycast(previous,delta,casts)==nil)
	local speed=(char:GetAttribute('MoveSpeed') :: number?) or 18
	if now<r.externalUntil then speed+=math.abs(r.externalX) end
	local supported=bounds and grounded(root,hum,casts)
	local accepted,reason=false,'bounds-or-obstacle'
	if clear then accepted,reason=Envelope.Check(r.motion,{x=p.X,y=p.Y,z=p.Z,at=now,grounded=supported},speed,Workspace.Gravity) end
	if accepted then
		if supported then r.safe=p end
		return true
	end
	local correction=if reason=='airborne-envelope' or not bounds then r.safe else previous
	root.CFrame=CFrame.new(correction); root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
	if correction~=previous then
		local credit=r.motion.credit
		r.motion=Envelope.New(correction.X,correction.Y,correction.Z,now,grounded(root,hum,casts))
		r.motion.credit=credit -- rejected motion cannot refill replication tolerance
	end
	notifyCorrection(char)
	return false
end

Players.PlayerRemoving:Connect(function(player) records[player]=nil end)
return Authority
