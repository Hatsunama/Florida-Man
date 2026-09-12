--!strict
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local PromptService=game:GetService("ProximityPromptService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes=require(Shared:WaitForChild("Remotes"))
local Weapons=require(Shared:WaitForChild("Weapons"))
local VFX=require(script.Parent:WaitForChild("VFX"))
local Anim=require(script.Parent:WaitForChild("AnimController"))
local State=require(script.Parent:WaitForChild("PresentationState"))
local Device=require(script.Parent:WaitForChild("DevicePolicy"))
local MenuPolicy=require(script.Parent:WaitForChild("MenuPolicy"))
local Input={}
local movement: any=nil
local state: any=nil
local enabled=true
local started=false
local readyAt=0
local serverOffset=0
local bufferedUntil=0
local dodgePendingUntil=0
local axes: { [string]: number }={}
local generation: any=nil
local interaction: ProximityPrompt?=nil
local prompts: { [ProximityPrompt]: boolean }={}
local Changed=Instance.new("BindableEvent")
Input.InteractionChanged=Changed.Event
local function facing(): number return if movement then movement.GetFacing() else 1 end
local function controllerUIOwnsMovement(): boolean
	local selected=GuiService.SelectedObject
	return MenuPolicy.ControllerUIOwnsMovement(State.IsModal(),selected~=nil,State.GameplayMenuOwnsSelection(selected))
end
local function available(action: string): boolean
	if not enabled or not state or state.characterReady~=true or State.IsModal() then return false end
	if state.phase~="Hub" and state.phase~="Active" then return false end
	if action=="move" or action=="jump" then return state.inHub==true or (state.runActive==true and (state.hp or 0)>0) end
	if action=="interact" then return typeof(state.allowedActions)=="table" and state.allowedActions.interact==true end
	if action=="weapon" then return state.inHub==true or (state.runActive==true and (state.hp or 0)>0) end
	if not state.runActive then return false end
	if typeof(state.allowedActions)~="table" or state.allowedActions.combat~=true then return false end
	if action=="swap" and #(state.personas or {})<2 then return false end
	return true
end
function Input.Can(action: string): boolean return available(action) end
function Input.GetCohort(): string
	return Device.Cohort(UIS:GetLastInputType().Name,UIS.TouchEnabled,UIS.KeyboardEnabled,UIS.GamepadEnabled)
end
function Input.UsesTouch(): boolean return Input.GetCohort()=="touch" end
function Input.ActionStatus(action: string): (boolean,number,boolean)
	local deadline=0
	if state then
		if action=="attack" then deadline=readyAt
		elseif action=="skill" then deadline=(state.skillReadyAt or 0)+serverOffset
		elseif action=="swap" then deadline=(state.swapReadyAt or 0)+serverOffset
		elseif action=="dodge" then deadline=(state.dodgeReadyAt or 0)+serverOffset end
	end
	local waiting=action=="dodge" and os.clock()<dodgePendingUntil
	local left=math.max(0,deadline-os.clock())
	return available(action) and left<=0 and not waiting and (action~="interact" or interaction~=nil),left,waiting
end
function Input.BindMovement(controller: any) movement=controller end
function Input.SetEnabled(value: boolean)
	enabled=value
	if not value then table.clear(axes); if movement then movement.SetMoveAxis(0); movement.SetJumpHeld(false) end end
end
function Input.SyncAttackReady(serverReadyAt: number?,serverNow: number?,recovery: number?)
	if typeof(serverNow)=="number" then serverOffset=os.clock()-serverNow end
	if typeof(serverReadyAt)=="number" then readyAt=serverReadyAt+serverOffset
	elseif typeof(recovery)=="number" then readyAt=os.clock()+recovery end
end
function Input.SetState(value: any)
	if typeof(value)~="table" then return end
	if generation~=value.generation then
		generation=value.generation
		bufferedUntil=0; readyAt=0; dodgePendingUntil=0
		table.clear(axes)
		if movement then movement.Reset() end
	end
	state=value
	Input.SyncAttackReady(value.attackReadyAt,value.serverNow,nil)
	if movement then
		movement.SetBaseSpeed(value.moveSpeed or 18)
	end
end
function Input.SetWeaponState(id: string?,unlocked: any)
	if not state then return end
	if id then state.weaponId=id end
	if unlocked then state.unlockedWeapons=unlocked end
end
local function weaponList(): { string }
	local ids={}
	for _,weapon in Weapons.List do if state and state.unlockedWeapons and state.unlockedWeapons[weapon.id] then table.insert(ids,weapon.id) end end
	return ids
end
local function attack()
	if not available("attack") then return end
	if os.clock()<readyAt then bufferedUntil=os.clock()+0.12; return end
	local now=os.clock()
	readyAt=now+0.12
	bufferedUntil=0
	if movement then movement.LockFacing(facing(),0.16) end
	Remotes.Get("RequestAttack"):FireServer(facing())
end
function Input.Intent(action: string,phase: string?,value: any?,source: string?)
	local begin=phase~="end"
	if action=="move" then
		axes[source or "touch"]=if begin and typeof(value)=="number" then math.clamp(value,-1,1) else 0
		return
	end
	if action=="jump" then
		if movement then movement.SetJumpHeld(begin and available("jump")) end
		return
	end
	if not begin or not available(action) then return end
	if action=="attack" then attack()
	elseif action=="skill" then Remotes.Get("RequestSkill"):FireServer(facing())
	elseif action=="swap" then Remotes.Get("RequestSwap"):FireServer(facing())
	elseif action=="dodge" then
		if os.clock()<dodgePendingUntil or os.clock()<(state.dodgeReadyAt or 0)+serverOffset then return end
		dodgePendingUntil=os.clock()+1
		Remotes.Get("RequestDodge"):FireServer(facing())
	elseif action=="weapon" then
		local ids=weaponList()
		if #ids==0 then return end
		local index=table.find(ids,state.weaponId) or 1
		local target=if typeof(value)=="string" and table.find(ids,value) then value elseif typeof(value)=="number" and value>=1 then ids[math.min(math.floor(value),#ids)] else ids[index%#ids+1]
		Remotes.Get("EquipWeapon"):FireServer(target)
	elseif action=="interact" and interaction and interaction.Parent then
		-- ProximityPrompt keeps one validated interaction path for click, controller and touch.
		interaction:InputHoldBegin()
		interaction:InputHoldEnd()
	end
end
function Input.TryAttack() Input.Intent("attack") end
function Input.CycleWeapon(_delta: number?) Input.Intent("weapon") end
function Input.GetInteraction(): ProximityPrompt? return interaction end
function Input.Result(result: any)
	if result.command=="RequestDodge" then dodgePendingUntil=0 end
end
function Input.AcceptAttack(event: any)
	Input.SyncAttackReady(event.attackReadyAt,event.serverNow,event.recovery)
	local char=Players.LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local acceptedFacing=if event.facing==-1 then -1 else 1
	if movement then movement.LockFacing(acceptedFacing,0.2) end
	Anim.PlayAttack(event.combo or 1)
	VFX.SwingSlash(root,acceptedFacing,event.combo,tostring(event.weaponVfx or "punch"))
end
function Input.AcceptDodge(event: any)
	dodgePendingUntil=0
	if typeof(event.serverNow)=="number" then serverOffset=os.clock()-event.serverNow end
	if state and typeof(event.dodgeReadyAt)=="number" then state.dodgeReadyAt=event.dodgeReadyAt end
	if movement then
		movement.ApplyDodge(if event.facing==-1 then -1 else 1)
	end
end
local function findInteraction()
	local char=Players.LocalPlayer.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	local world=workspace:FindFirstChild("GameWorld")
	local nearest: ProximityPrompt?=nil
	local distance=math.huge
	if available("interact") and root and root:IsA("BasePart") and world then
		for object in prompts do
			if object:IsDescendantOf(world) and object.Enabled and object:GetAttribute("FM_Action") then
				local parent=object.Parent
				local position: Vector3?=nil
				if parent and parent:IsA("BasePart") then position=parent.Position
				elseif parent and parent:IsA("Attachment") then position=parent.WorldPosition end
				if position then
					local d=(position-root.Position).Magnitude
					if d<=object.MaxActivationDistance and d<distance then nearest=object; distance=d end
				end
			end
		end
	end
	if interaction~=nearest then interaction=nearest; Changed:Fire(nearest) end
end
function Input.Start()
	if started then return end
	started=true
	local function track(object: Instance)
		if object:IsA("ProximityPrompt") then
			prompts[object]=true
			object.KeyboardKeyCode=Enum.KeyCode.E
			object.GamepadKeyCode=Enum.KeyCode.ButtonL1
			object.Exclusivity=Enum.ProximityPromptExclusivity.OneGlobally
		end
	end
	workspace.DescendantAdded:Connect(track)
	workspace.DescendantRemoving:Connect(function(object) if object:IsA("ProximityPrompt") then prompts[object]=nil end end)
	for _,object in workspace:GetDescendants() do track(object) end
	local keys: { [Enum.KeyCode]: boolean }={}
	State.Changed:Connect(function()
		if State.IsModal() then
			table.clear(keys); table.clear(axes); bufferedUntil=0
			if movement then movement.SetMoveAxis(0); movement.SetJumpHeld(false) end
		end
	end)
	local function moveKeys()
		local left=keys[Enum.KeyCode.A] or keys[Enum.KeyCode.Left]
		local right=keys[Enum.KeyCode.D] or keys[Enum.KeyCode.Right]
		Input.Intent("move","begin",(if right then 1 else 0)-(if left then 1 else 0),"keyboard")
	end
	CAS:BindActionAtPriority("FM_Move",function(_,phase,input)
		if UIS:GetFocusedTextBox() then table.clear(keys); moveKeys(); return Enum.ContextActionResult.Pass end
		keys[input.KeyCode]=phase==Enum.UserInputState.Begin
		moveKeys()
		return Enum.ContextActionResult.Sink
	end,false,3000,Enum.KeyCode.A,Enum.KeyCode.D,Enum.KeyCode.Left,Enum.KeyCode.Right)
	CAS:BindActionAtPriority("FM_Stick",function(_,phase,input)
		if controllerUIOwnsMovement() then
			Input.Intent("move","end",0,"gamepad")
			return Enum.ContextActionResult.Pass
		end
		Input.Intent("move",if phase==Enum.UserInputState.End then "end" else "begin",if math.abs(input.Position.X)>0.18 then input.Position.X else 0,"gamepad")
		return Enum.ContextActionResult.Sink
	end,false,3000,Enum.KeyCode.Thumbstick1)
	local bindings={
		{action="jump",keys={Enum.KeyCode.Space,Enum.KeyCode.ButtonA}},
		{action="attack",keys={Enum.KeyCode.J,Enum.KeyCode.ButtonX,Enum.KeyCode.ButtonR2}},
		{action="skill",keys={Enum.KeyCode.K,Enum.KeyCode.ButtonY,Enum.KeyCode.ButtonL2}},
		{action="swap",keys={Enum.KeyCode.Q,Enum.KeyCode.ButtonB}},
		{action="dodge",keys={Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonR1}},
		{action="weapon",keys={Enum.KeyCode.R,Enum.KeyCode.DPadRight}},
	}
	for _,binding in bindings do
		CAS:BindActionAtPriority("FM_"..binding.action,function(_,phase,input)
			if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
			if input.KeyCode==Enum.KeyCode.ButtonA and controllerUIOwnsMovement() then return Enum.ContextActionResult.Pass end
			Input.Intent(binding.action,if phase==Enum.UserInputState.Begin then "begin" else "end")
			return if available(binding.action) then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
		end,false,3000,table.unpack(binding.keys))
	end
	UIS.InputBegan:Connect(function(input,processed)
		if processed then return end
		if input.UserInputType==Enum.UserInputType.MouseButton1 then Input.Intent("attack")
		elseif input.KeyCode==Enum.KeyCode.One then Input.Intent("weapon","begin",1)
		elseif input.KeyCode==Enum.KeyCode.Two then Input.Intent("weapon","begin",2)
		elseif input.KeyCode==Enum.KeyCode.Three then Input.Intent("weapon","begin",3) end
	end)
	UIS.WindowFocusReleased:Connect(function()
		table.clear(keys); table.clear(axes)
		if movement then movement.SetMoveAxis(0); movement.SetJumpHeld(false) end
	end)
	local scan=0
	RunService.Heartbeat:Connect(function(dt)
		-- Native prompts own E/LB exactly once. Touch USE activates the same prompt.
		PromptService.Enabled=available("interact")
		local axis=0
		for _,value in axes do if math.abs(value)>math.abs(axis) then axis=value end end
		if movement then movement.SetEnabled(available("move")); movement.SetMoveAxis(if available("move") then axis else 0) end
		if bufferedUntil>0 and os.clock()>=readyAt then
			if os.clock()<=bufferedUntil and available("attack") then attack() else bufferedUntil=0 end
		end
		scan+=dt
		if scan>=0.15 then scan=0; findInteraction() end
	end)
end
return Input
