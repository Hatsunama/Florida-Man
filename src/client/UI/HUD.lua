--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings=require(Shared:WaitForChild("Settings"))
local Remotes=require(Shared:WaitForChild("Remotes"))
local Stages=require(Shared:WaitForChild("Stages"))
local Personas=require(Shared:WaitForChild("Personas"))
local Weapons=require(Shared:WaitForChild("Weapons"))
local Items=require(Shared:WaitForChild("Items"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Layout=require(script.Parent:WaitForChild("GameplayLayout"))
local Tagline=require(script.Parent:WaitForChild("Tagline"))
local Presentation=require(script.Parent.Parent.Controllers:WaitForChild("PresentationState"))
local Input=require(script.Parent.Parent.Controllers:WaitForChild("InputController"))
local HUD={}
local gui: ScreenGui?=nil
local statsLabel: TextLabel?=nil
local stageLabel: TextLabel?=nil
local cooldownLabel: TextLabel?=nil
local state: any=nil
local clockOffset=0
local options: ScreenGui?=nil
local journal: ScreenGui?=nil
local lastToast=""
local lastToastAt=-math.huge
local function anotherPanelOwnsFocus(): boolean
	return Presentation.IsModal() and not (options and options.Parent) and not (journal and journal.Parent)
end
local function safeMenu(): boolean
	if anotherPanelOwnsFocus() or (state and state.awaitingDraft) then return false end
	if state and (state.phase=="Hub" or state.phase=="Recovering" or state.phase=="Reward") then return true end
	HUD.Toast("Open Options and Notes at the bonfire or between encounters.")
	return false
end
local function openJournal()
	if journal and journal.Parent then journal:Destroy(); journal=nil; return end
	if not safeMenu() then return end
	local screen,scroll=UiKit.Panel("FM_Journal","Notes & equipment",520,true)
	journal=screen
	UiKit.Focus(UiKit.Button(scroll,"Close",function() screen:Destroy(); journal=nil end))
	if state then
		local persona=Personas.Get((state.personas or {})[state.activePersona or 1] or "BeachBurnout")
		UiKit.Paragraph(scroll,(if persona then persona.name else "Persona").." · Sunburn "..tostring(state.sunburn or 0))
		local owned={}
		for _,id in state.items or {} do local item=Items.Get(id); table.insert(owned,if item then item.name else tostring(id)) end
		UiKit.Paragraph(scroll,"Bag "..#owned.."/"..tostring(state.itemSlots or 0)..": "..(if #owned>0 then table.concat(owned,", ") else "Empty"))
		UiKit.Paragraph(scroll,"Unlocked weapons")
		for _,weapon in Weapons.List do
			if state.unlockedWeapons and state.unlockedWeapons[weapon.id] then
				UiKit.Button(scroll,(if state.weaponId==weapon.id then "✓ " else "")..weapon.name,function()
					Remotes.Get("EquipWeapon"):FireServer(weapon.id)
				end)
				UiKit.Paragraph(scroll,weapon.description)
			end
		end
	end
	for _,line in Tagline.History() do UiKit.Paragraph(scroll,tostring(line.speaker)..": "..tostring(line.text)) end
end
local function openOptions()
	if options and options.Parent then options:Destroy(); options=nil; return end
	if anotherPanelOwnsFocus() or (state and state.awaitingDraft) then return end
	if state and state.runActive then
		local screen=UiKit.Screen("FM_CombatMenu",60); options=screen
		Tagline.SetObscured(true)
		screen.Destroying:Connect(function()
			Tagline.SetObscured(false)
			local selected=GuiService.SelectedObject
			if selected and selected:IsDescendantOf(screen) then GuiService.SelectedObject=nil end
		end)
		local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(1,0); panel.Position=UDim2.new(1,-12,0,58)
		panel.Size=UDim2.fromOffset(224,140); panel.BackgroundColor3=UiKit.Colors.background; panel.Parent=screen; UiKit.Corner(panel)
		local text=UiKit.Text(panel,"Run continues",14); text.Position=UDim2.fromOffset(8,6); text.Size=UDim2.fromOffset(208,20)
		local close=UiKit.Button(panel,"Close · Tab / D-pad ←",function() screen:Destroy(); options=nil end)
		close.Position=UDim2.fromOffset(8,32); close.Size=UDim2.fromOffset(208,44); UiKit.Focus(close)
		local confirm=false
		local abandon: TextButton
		abandon=UiKit.Button(panel,"Return to bonfire",function()
			if not confirm then confirm=true; abandon.Text="End this run and return"; return end
			Remotes.Get("ReturnToHub"):FireServer(); screen:Destroy(); options=nil
		end)
		abandon.Position=UDim2.fromOffset(8,84); abandon.Size=UDim2.fromOffset(208,44)
		return
	end
	if not safeMenu() then return end
	local screen,scroll=UiKit.Panel("FM_Options","Options",420,true)
	options=screen
	UiKit.Focus(UiKit.Button(scroll,"Close",function() screen:Destroy(); options=nil end))
	UiKit.Button(scroll,"Notes & equipment",openJournal)
	local rows={{"Screen shake","ShakeEnabled"},{"Patterned danger cues","ColorblindTelegraphs"},{"Reduce motion","ReduceMotion"},{"Reduce flashes","ReduceFlashes"},{"Large text","LargeText"}}
	for _,row in rows do
		local button: TextButton
		local function refresh() button.Text=row[1]..": "..(if Settings.GetBool(Players.LocalPlayer,row[2]) then "On" else "Off") end
		button=UiKit.Button(scroll,"",function()
			local nextValue=Settings.Toggle(Players.LocalPlayer,row[2]); Remotes.Get("SyncSettings"):FireServer(row[2],nextValue); refresh()
		end)
		refresh()
		local changed=Players.LocalPlayer:GetAttributeChangedSignal(row[2]):Connect(refresh)
		button.Destroying:Once(function() changed:Disconnect() end)
	end
	local speed: TextButton
	speed=UiKit.Button(scroll,"Text speed: "..Settings.GetTextSpeed(Players.LocalPlayer),function()
		local value=Settings.CycleTextSpeed(Players.LocalPlayer); Remotes.Get("SyncSettings"):FireServer("TextSpeed",value)
	end)
	local changed=Players.LocalPlayer:GetAttributeChangedSignal("TextSpeed"):Connect(function() speed.Text="Text speed: "..Settings.GetTextSpeed(Players.LocalPlayer) end)
	speed.Destroying:Once(function() changed:Disconnect() end)
	UiKit.Paragraph(scroll,"Move A/D or stick · Jump Space/A · Attack J/X · Skill K/Y · Dodge Shift/RB · Swap Q/B · Weapon R/D-pad → · Use E/LB · Dialogue T/D-pad ↑")
	local identity=game:GetService("ReplicatedStorage"):FindFirstChild("BuildIdentity")
	if identity and identity:IsA("StringValue") then
		local debugLabel=UiKit.Paragraph(scroll,"Build "..string.sub(identity.Value,1,12))
		debugLabel.TextSize=12; debugLabel:SetAttribute("FM_BaseTextSize",12); debugLabel.TextColor3=UiKit.Colors.muted
	end
	if state and state.inHub then UiKit.Button(scroll,"Replay controls tutorial",function() Remotes.Get("ReplayTutorial"):FireServer(); screen:Destroy(); options=nil end) end
	UiKit.Button(scroll,"Return to bonfire",function() Remotes.Get("ReturnToHub"):FireServer(); screen:Destroy(); options=nil end)
end
function HUD.Init(_controller: any)
	if gui and gui.Parent then return end
	local screen=UiKit.Screen("FloridaManHUD",10); gui=screen
	local panel=Instance.new("Frame")
	panel.BackgroundColor3=UiKit.Colors.background; panel.BackgroundTransparency=0.15; panel.Parent=screen; UiKit.Corner(panel)
	local stats=UiKit.Text(panel,"Connecting…",15)
	stats.Position=UDim2.fromOffset(10,11); stats.Size=UDim2.fromOffset(114,24); stats.TextWrapped=false; stats.Font=Enum.Font.GothamBold; statsLabel=stats
	local stage=UiKit.Text(panel,"",14)
	stage.Position=UDim2.fromOffset(126,12); stage.Size=UDim2.new(1,-180,0,22); stage.TextWrapped=false; stage.TextTruncate=Enum.TextTruncate.AtEnd; stageLabel=stage
	local menu=UiKit.Button(panel,"Tab",openOptions)
	menu.Position=UDim2.new(1,-44,0,0); menu.Size=UDim2.fromOffset(44,44)
	local cds=UiKit.Text(screen,"",13)
	cds.AnchorPoint=Vector2.new(1,1); cds.Position=UDim2.new(1,-12,1,-10); cds.Size=UDim2.new(1,-24,0,22)
	cds.TextXAlignment=Enum.TextXAlignment.Right; cds.TextWrapped=false; cooldownLabel=cds
	local tick=0
	local connection=RunService.Heartbeat:Connect(function(dt)
		tick+=dt; if tick<0.1 then return end; tick=0
		local camera=workspace.CurrentCamera
		if camera then
			local inset,tail=GuiService:GetGuiInset()
			local rect=Layout.Hud(camera.ViewportSize.X-inset.X-tail.X)
			panel.Position=UDim2.fromOffset(rect.x,rect.y); panel.Size=UDim2.fromOffset(rect.width,rect.height)
		end
		HUD.RefreshCds()
	end)
	screen.Destroying:Connect(function() connection:Disconnect() end)
	CAS:BindActionAtPriority("FM_Options",function(_,phase)
		if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if phase==Enum.UserInputState.Begin then
			if journal and journal.Parent then journal:Destroy(); journal=nil else openOptions() end
		end
		return Enum.ContextActionResult.Sink
	end,false,3000,Enum.KeyCode.Tab,Enum.KeyCode.O,Enum.KeyCode.DPadLeft)
	CAS:BindActionAtPriority("FM_CombatMenuBack",function(_,phase)
		if options and options.Parent and options.Name=="FM_CombatMenu" then
			if phase==Enum.UserInputState.Begin then options:Destroy(); options=nil end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end,false,4000,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
end
function HUD.RefreshCds()
	if not cooldownLabel then return end
	local parts={}
	if state and state.runActive and not Input.UsesTouch() then
		local function addCooldown(label: string,deadline: number?)
			local left=math.max(0,(deadline or 0)+clockOffset-os.clock())
			if left>0.05 then table.insert(parts,label.." "..string.format("%.1fs",left)) end
		end
		addCooldown("K Skill",state.skillReadyAt)
		addCooldown("Q Swap",state.swapReadyAt)
		addCooldown("Shift Dodge",state.dodgeReadyAt)
	end
	cooldownLabel.Text=table.concat(parts," · "); cooldownLabel.Visible=#parts>0
end
function HUD.Update(value: any)
	if typeof(value)~="table" then return end
	local old=state; state=value
	if typeof(value.serverNow)=="number" then clockOffset=os.clock()-value.serverNow end
	if statsLabel then statsLabel.Text=if value.inHub then "Bonfire" else string.format("HP %d/%d",math.floor(value.hp or 0),math.floor(value.maxHp or 100)) end
	if stageLabel then
		local stage=Stages.Get(value.stageId)
		local boss=value.boss
		stageLabel.Text=if value.inHub then "Use E / LB nearby" elseif typeof(boss)=="table" and (boss.hp or 0)>0 then tostring(boss.name).." "..tostring(math.ceil(boss.hp)).." HP"
			elseif (value.turtlesNeeded or 0)>0 then "Turtles "..tostring(value.turtlesRescued or 0).."/"..tostring(value.turtlesNeeded)
			elseif value.coldOneRequired and not value.coldOneTaken then "Collect the Cold One"
			else if stage then stage.name else "Florida Man"
	end
	if old and old.weaponId~=value.weaponId then local weapon=Weapons.Get(value.weaponId); if weapon then HUD.Toast("Equipped "..weapon.name..".") end end
	if value.runActive then
		if options and options.Name~="FM_CombatMenu" then options:Destroy(); options=nil end
		if journal then journal:Destroy(); journal=nil end
	end
	HUD.RefreshCds()
end
function HUD.Toast(text: string)
	if text==lastToast and os.clock()-lastToastAt<2 then return end
	lastToast=text; lastToastAt=os.clock()
	Tagline.Show({text=text,speaker="Tip",essential=false})
end
function HUD.FlashCancel(_label: string) end -- Accepted timing is shown by action availability, not a second popup.
function HUD.FlashPunish() end -- Swap animation and confirmed impact already provide feedback.
return HUD
