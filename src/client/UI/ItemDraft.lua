--!strict
local Remotes=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Tagline=require(script.Parent:WaitForChild("Tagline"))
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items=require(Shared:WaitForChild("Items"))
local Constants=require(Shared:WaitForChild("Constants"))
local Draft={}
local gui: ScreenGui?=nil
local offer: any=nil
local selected: any=nil
local pending: any=nil
local status: TextLabel?=nil
local function preview(item: any,replaceIndex: number?): string
	local ids: {string}={}
	for index,owned in offer.items or {} do
		if index~=replaceIndex then table.insert(ids,if typeof(owned)=="table" then owned.id else owned) end
	end
	if item then table.insert(ids,item.id) end
	local counts=Items.CountInscriptions(ids)
	local names={}
	for name,count in counts do
		if count>0 then table.insert(names,name.." "..tostring(count).."/"..tostring(Constants.INSCRIPTION_SET_SIZE)..(if count>=Constants.INSCRIPTION_SET_SIZE then " ✓" else "")) end
	end
	table.sort(names)
	return "Resulting inscriptions: "..table.concat(names," · ")
end
function Draft.Close()
	if gui then gui:Destroy(); gui=nil end
	offer=nil; selected=nil; pending=nil; status=nil
end
local function submit(item: any,replacement: number?,skip: boolean?)
	if not offer or pending then return end
	pending={offerId=offer.offerId,generation=offer.generation,itemId=if item then item.id else nil,replaceIndex=replacement,skip=skip}
	if status then status.Text="Waiting for the island…" end
	Remotes.Get("PickDraftItem"):FireServer(pending)
end
local function render()
	if not offer then return end
	local full=offer.full==true
	local screen,scroll=UiKit.Panel("FM_Draft","Choose your next item",560,true)
	gui=screen
	status=UiKit.Paragraph(scroll,if full then "Your bag is full. Choose an item, then choose what to replace." else "Pick one reward. Three matching inscriptions unlock a set.")
	if selected then
		UiKit.Paragraph(scroll,"Taking "..tostring(selected.name)..". Replace:")
		local firstReplacement: TextButton?=nil
		for index,item in offer.items or {} do
			local itemName=if typeof(item)=="table" then item.name or item.id else item
			local replacement=UiKit.Button(scroll,tostring(itemName),function() submit(selected,index,false) end)
			if not firstReplacement then firstReplacement=replacement end
			if typeof(item)=="table" then UiKit.Paragraph(scroll,"Giving up: "..tostring(item.statText or "").."\n"..preview(selected,index)) end
		end
		UiKit.Focus(firstReplacement)
		UiKit.Button(scroll,"Back to choices",function() selected=nil; render() end)
	else
		local first: TextButton?=nil
		for _,item in offer.picks or {} do
			local button=UiKit.Button(scroll,tostring(item.name).." · "..tostring(item.rarity).." · "..tostring(item.inscription),function()
				if pending then return end
				if full then selected=item; render() else submit(item,nil,false) end
			end)
			if not first then first=button end
			UiKit.Paragraph(scroll,tostring(item.statText or "").."\n"..tostring(item.description or ""))
			if not full then UiKit.Paragraph(scroll,preview(item,nil)) end
		end
		UiKit.Focus(first)
	end
	UiKit.Button(scroll,"Keep my items and continue",function() submit(nil,nil,true) end)
	UiKit.Button(scroll,"Retry pending choice",function()
		if pending then Remotes.Get("PickDraftItem"):FireServer(pending)
		elseif status then status.Text="Choose an item above, or keep your current items." end
	end)
end
function Draft.Show(value: any)
	if typeof(value)~="table" or typeof(value.offerId)~="string" then return end
	if offer and offer.offerId==value.offerId and gui and gui.Parent then return end
	Draft.Close(); offer=value; render()
end
function Draft.Update(state: any)
	if state.pendingOffer then Draft.Show(state.pendingOffer)
	elseif state.awaitingDraft==false then Draft.Close() end
end
function Draft.Result(result: any)
	if result.command~="PickDraftItem" then return end
	if offer and result.offerId and result.offerId~=offer.offerId then return end
	if result.accepted then Draft.Close() else
		pending=nil
		if status then status.Text=result.reason or "That choice was not accepted. Choose again." end
		Tagline.Show({text=result.reason or "Choose another item.",speaker="Item choice",essential=false})
	end
end
return Draft
