--!strict
-- Client composition owns presentation and intent. Server snapshots own progression and permissions.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local StarterGui=game:GetService("StarterGui")
-- Hide duplicate gameplay overlays; retain the Roblox menu and platform controls.
task.spawn(function()
 for _=1,8 do
  local ok=pcall(function()
   for _,kind in {Enum.CoreGuiType.Chat,Enum.CoreGuiType.PlayerList,Enum.CoreGuiType.Health,Enum.CoreGuiType.Backpack} do
    StarterGui:SetCoreGuiEnabled(kind,false)
   end
  end)
  if ok then return end
  task.wait(0.25)
 end
end)
local Shared=ReplicatedStorage:WaitForChild("Shared")
local Remotes=require(Shared:WaitForChild("Remotes"))
local Settings=require(Shared:WaitForChild("Settings"))
local Stages=require(Shared:WaitForChild("Stages"))
local Controllers=script:WaitForChild("Controllers")
local UI=script:WaitForChild("UI")
local Silence=require(Controllers:WaitForChild("SilenceController"))
Silence.Start()
local Input=require(Controllers:WaitForChild("InputController"))
local Camera=require(Controllers:WaitForChild("CameraController"))
local Movement=require(Controllers:WaitForChild("MovementController"))
local Anim=require(Controllers:WaitForChild("AnimController"))
local Presentation=require(Controllers:WaitForChild("PresentationState"))
local Accessibility=require(Controllers:WaitForChild("AccessibilityController"))
local Equipment=require(Controllers:WaitForChild("EquipmentController"))
local VFX=require(Controllers:WaitForChild("VFX"))
local HUD=require(UI:WaitForChild("HUD"))
local Newspaper=require(UI:WaitForChild("Newspaper"))
local Draft=require(UI:WaitForChild("ItemDraft"))
local Credits=require(UI:WaitForChild("Credits"))
local Tagline=require(UI:WaitForChild("Tagline"))
local Steve=require(UI:WaitForChild("CaptainSteveUI"))
local Mobile=require(UI:WaitForChild("MobileControls"))
local Loading=require(UI:WaitForChild("LoadingGui"))
local player=Players.LocalPlayer
local hasState=false
local lastGeneration: number?=nil
local lastVersion=-1
Settings.EnsureDefaults(player)
Loading.Init()
HUD.Init(Input)
Anim.Start()
Movement.Start()
Camera.Start()
Input.BindMovement(Movement)
Input.Start()
Mobile.Init(Input)
Accessibility.Start()
Equipment.Start()
local function ready()
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local state=Presentation.Get()
 if hasState and state and state.characterReady==true and state.phase~="Loading" and root and root:IsA("BasePart") then Loading.Ready() end
end
Remotes.Get("StateUpdate").OnClientEvent:Connect(function(state)
 if typeof(state)~="table" then return end
 if typeof(state.generation)=="number" and lastGeneration and state.generation<lastGeneration then return end
 if state.generation==lastGeneration and typeof(state.stateVersion)=="number" and state.stateVersion<=lastVersion then return end
 if typeof(state.stateVersion)=="number" then lastVersion=state.stateVersion end
 if lastGeneration~=state.generation then
  lastGeneration=state.generation
  local stage=Stages.Get(state.stageId)
  Camera.Reset(if stage then stage.length else nil)
  Tagline.SetGeneration(state.generation,state.phase)
  Newspaper.Close()
  Credits.Close()
 end
 Presentation.Update(state)
 if typeof(state.settings)=="table" then
  for _,key in Settings.BOOL_KEYS do
   if typeof(state.settings[key])=="boolean" then Settings.SetBool(player,key,state.settings[key]) end
  end
  if typeof(state.settings.TextSpeed)=="string" then Settings.SetTextSpeed(player,state.settings.TextSpeed) end
 end
 Input.SetState(state)
 HUD.Update(state)
 Steve.SetState(state)
 Draft.Update(state)
 if state.awaitingNewspaper==false then Newspaper.Close() end
 if state.phase~="Ending" then Credits.Close() end
 local persona=(state.personas or {})[state.activePersona or 1]
 if typeof(persona)=="string" then Anim.SetPersona(persona) end
 hasState=true
 ready()
end)
Remotes.Get("Toast").OnClientEvent:Connect(function(text) if typeof(text)=="string" then HUD.Toast(text) end end)
Remotes.Get("ShowTagline").OnClientEvent:Connect(function(value,speaker) Tagline.Show(value,speaker) end)
Remotes.Get("ShowNewspaper").OnClientEvent:Connect(Newspaper.Show)
Remotes.Get("ShowDraft").OnClientEvent:Connect(function(offer) Newspaper.Close(); Draft.Show(offer) end)
Remotes.Get("ShowCredits").OnClientEvent:Connect(Credits.Show)
Remotes.Get("OpenShop").OnClientEvent:Connect(function() Steve.Open() end)
Remotes.Get("StageLoaded").OnClientEvent:Connect(function(stageId)
 local stage=Stages.Get(stageId)
 Camera.Reset(if stage then stage.length else nil)
 Newspaper.Close()
 Credits.Close()
end)
Remotes.Get("CommandResult").OnClientEvent:Connect(function(result)
 if typeof(result)~="table" then return end
 Newspaper.Result(result); Draft.Result(result); Steve.Result(result); Credits.Result(result); Input.Result(result)
 if result.accepted==false and result.command~="ContinueFromNewspaper" and result.command~="PickDraftItem"
  and result.command~="EquipPersona" and result.command~="SmashPersona" and result.command~="UpgradePersona" and result.command~="DismissCredits" then
  HUD.Toast(result.reason or "That action is unavailable right now.")
 end
end)
-- Bounded visual damage labels. They never intercept movement or query casts.
local damageLabels=0
Remotes.Get("DamageNumber").OnClientEvent:Connect(function(pos,amount,isPlayer)
 if typeof(pos)~="Vector3" or typeof(amount)~="number" or amount~=amount or damageLabels>=18 then return end
 damageLabels+=1
 local part=Instance.new("Part")
 part.Name="FM_DamageText"; part.Anchored=true; part.CanCollide=false; part.CanQuery=false; part.CanTouch=false; part.Transparency=1
 part.Size=Vector3.one; part.Position=pos+Vector3.new(0,3,0); part.Parent=workspace
 local bb=Instance.new("BillboardGui")
 bb.Size=UDim2.fromOffset(80,40); bb.AlwaysOnTop=true; bb.Adornee=part; bb.Parent=part
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Font=Enum.Font.GothamBold
 label.TextSize=if Settings.GetBool(player,"LargeText") then 22 else 18
 label.TextColor3=if isPlayer then Color3.fromRGB(255,240,230) else Color3.fromRGB(255,220,80)
 label.TextStrokeTransparency=0.4; label.Text=tostring(math.floor(amount)); label.Parent=bb
 if not Settings.IsReduceMotion(player) then TweenService:Create(part,TweenInfo.new(0.6),{Position=part.Position+Vector3.new(0,2,0)}):Play() end
 part.Destroying:Once(function() damageLabels-=1 end)
 Debris:AddItem(part,0.65)
end)
Remotes.Get("CombatEvent").OnClientEvent:Connect(function(event)
 if typeof(event)~="table" then return end
 local kind=event.kind
 if kind=="shake" then Camera.Shake(event.amount or 0.4,0.18); return end
 if kind=="focus" then if typeof(event.pos)=="Vector3" then Camera.Focus(event.pos,event.duration) end; return end
 if kind=="arenaLock" then if typeof(event.pos)=="Vector3" then Camera.LockArena(event.pos) end; HUD.Toast("Clear the room to open the gate."); return end
 if kind=="arenaUnlock" then Camera.UnlockArena(event.pos); HUD.Toast("Room clear."); return end
 if kind=="cancelWindow" then HUD.FlashCancel(tostring(event.label or "Swap cancel ready")); return end
 if kind=="hitConnect" then
  Anim.Hitstop(event.hitstop or 0.04)
  if typeof(event.pos)=="Vector3" then VFX.HitSpark(event.pos,event.heavy==true) end
  Camera.Shake(event.amount or 0.3,0.14)
  return
 end
 if kind=="attack" then Input.AcceptAttack(event) end
 if kind=="dodge" then Input.AcceptDodge(event); return end
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") then return end
 local facing=if typeof(event.facing)=="number" then event.facing else Movement.GetFacing()
 if kind=="attack" then Movement.LockFacing(facing,0.2)
 elseif kind=="skill" then Anim.PlaySkill(); VFX.SkillPattern(root,tostring(event.skillKind or "aoe"),facing); Camera.Shake(0.35,0.18)
 elseif kind=="swap" then
  if typeof(event.personaId)=="string" then Anim.SetPersona(event.personaId) end
  Anim.PlaySwap()
  local color=Color3.fromRGB(255,160,40)
  if typeof(event.color)=="table" and #event.color==3 then color=Color3.new(event.color[1],event.color[2],event.color[3]) end
  VFX.SwapBurst(root,color)
  if event.punish then HUD.FlashPunish() end
  Camera.Shake(0.3,0.15)
 elseif kind=="hit" then Camera.Shake(0.45,0.2) end
end)
player.CharacterAdded:Connect(function(char)
 local root=char:WaitForChild("HumanoidRootPart",10)
 if player.Character==char and root then ready() end
end)
-- Listener registration precedes handshake, so loading and initial UI use real snapshot readiness.
local function hello()
 Remotes.Get("ClientReady"):FireServer({cohort=Input.GetCohort()})
end
hello()
task.spawn(function()
 while not hasState do task.wait(2); if not hasState then hello() end end
end)
ready()
