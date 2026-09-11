--!strict
local HttpService=game:GetService("HttpService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Remotes=require(Shared:WaitForChild("Remotes"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Tagline=require(script.Parent:WaitForChild("Tagline"))
local Steve={}
local state: any=nil
local gui: ScreenGui?=nil
local busy=false
local pending: any=nil
local pendingCommand=""
local sequence=0
local status: TextLabel?=nil
local retryButton: TextButton?=nil
local function command(name: string,id: string,slot: number?)
	if busy then return end
	sequence+=1
	pending={personaId=id,slot=slot,requestId=HttpService:GenerateGUID(false),sequence=sequence,generation=state.generation}
	pendingCommand=name
	busy=true
	if retryButton then retryButton.Visible=true end
	if status then status.Text="Waiting for Captain Steve…" end
	Remotes.Get(name):FireServer(pending)
end
local function render()
	if not state then return end
	local panel,scroll=UiKit.Panel("FM_Steve","Captain Steve · Loadout & upgrades",560,true)
	gui=panel
	status=UiKit.Paragraph(scroll,"Sunburn: "..tostring(state.sunburn or 0).."\nChoose two personas. Upgrades last between runs.")
	local close=UiKit.Button(scroll,"Close",function() Steve.Close() end)
	UiKit.Focus(close)
	if state.profileStatus and not state.profileStatus.writable then UiKit.Paragraph(scroll,"Cloud progress is unavailable. This run is temporary; purchases are disabled.") end
	for _,item in state.shop or {} do
		if item.owned then
			local slots={}
			for _,slot in item.slots or {} do table.insert(slots,tostring(slot)) end
			UiKit.Paragraph(scroll,tostring(item.name).." · "..tostring(item.rarity)..(if #slots>0 then " · Slot "..table.concat(slots,", ") else ""))
			if item.canEquip then
				UiKit.Button(scroll,"Equip in slot 1",function() command("EquipPersona",item.id,1) end)
				UiKit.Button(scroll,"Equip in slot 2",function() command("EquipPersona",item.id,2) end)
			end
			if item.canUpgrade then
				local nextRarity=item.nextRarity
				local power=item.nextDamageBonusPercent or 0
				local cdr=item.nextSkillCooldownReductionPercent or 0
				UiKit.Button(scroll,"Upgrade to "..tostring(nextRarity).." · "..tostring(item.upgradeCost).." Sunburn",function() command("UpgradePersona",item.id) end)
				UiKit.Paragraph(scroll,"Attack/skill damage +"..power.."%; skill cooldown −"..cdr.."%. Shield/heal amounts stay fixed.")
			elseif item.upgradeCost then UiKit.Paragraph(scroll,"Next upgrade: "..tostring(item.upgradeCost).." Sunburn (unavailable).") end
			if item.canSmash then
				UiKit.Button(scroll,"Smash "..tostring(item.name).." for "..tostring(item.refund).." Sunburn",function() command("SmashPersona",item.id) end)
				UiKit.Paragraph(scroll,"Smashing removes this persona and its upgrades. Equipped personas cannot be smashed.")
			end
		end
	end
	if #(state.personas or {})>1 then UiKit.Button(scroll,"Clear persona slot 2",function() command("EquipPersona","",2) end) end
	local retry=UiKit.Button(scroll,"Retry pending action",function() if pending then Remotes.Get(pendingCommand):FireServer(pending) end end)
	retry.Visible=pending~=nil
	retryButton=retry
end
function Steve.SetState(value: any)
	state=value
	sequence=math.max(sequence,value.shopSequence or 0)
	if pending and pending.generation~=value.generation then pending=nil; busy=false end
	if gui and gui.Parent then
		if not state.inHub then Steve.Close()
		elseif not busy then render() end
	end
end
function Steve.Open()
	if not state or not state.inHub then return end
	render()
end
function Steve.Close()
	if gui then gui:Destroy(); gui=nil end
	status=nil
	retryButton=nil
end
function Steve.Result(result: any)
	if result.command~="UpgradePersona" and result.command~="SmashPersona" and result.command~="EquipPersona" then return end
	if not pending or result.requestId~=pending.requestId then return end
	busy=false
	if result.accepted then pending=nil end
	if gui and gui.Parent then render() end
	if status then status.Text=result.reason or (if result.accepted then "Done." else "That action was not accepted.") end
	if not result.accepted then Tagline.Show({text=result.reason or "Try a different action.",speaker="Captain Steve",essential=false}) end
end
return Steve
