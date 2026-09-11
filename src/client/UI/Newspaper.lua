--!strict
local Remotes=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Tagline=require(script.Parent:WaitForChild("Tagline"))
local Newspaper={}
local gui: ScreenGui?=nil
local button: TextButton?=nil
local pending=false
local sentAt=-math.huge
function Newspaper.Close()
	if gui then gui:Destroy(); gui=nil end
	button=nil; pending=false; sentAt=-math.huge
end
function Newspaper.Show(payload: any)
	if typeof(payload)~="table" then return end
	Newspaper.Close()
	Tagline.Show({id="stage-summary:"..tostring(payload.stageName),text=tostring(payload.headline or "Stage cleared.").." "..tostring(payload.storyBeat or ""),speaker="The Daily Swamp",generation=payload.generation,priority=10,scope="run"})
	gui=UiKit.Screen("FM_Newspaper",45)
	local panel=Instance.new("Frame")
	panel.AnchorPoint=Vector2.new(0.5,1)
	panel.Position=UDim2.new(0.5,0,1,-16)
	panel.Size=UDim2.new(1,-24,0,110)
	panel.BackgroundColor3=UiKit.Colors.background
	panel.Parent=gui
	UiKit.Corner(panel)
	local limit=Instance.new("UISizeConstraint")
	limit.MaxSize=Vector2.new(420,110)
	limit.Parent=panel
	local label=UiKit.Text(panel,"Cleared: "..tostring(payload.stageName or "stage"),16)
	label.Position=UDim2.fromOffset(12,10)
	label.Size=UDim2.new(1,-24,0,38)
	local continueButton=UiKit.Button(panel,if payload.isFinale then "Continue to sunrise" else "Continue",function()
		if pending and os.clock()-sentAt<2 then return end
		pending=true
		sentAt=os.clock()
		if button then button.Text="Continuing…" end
		Remotes.Get("ContinueFromNewspaper"):FireServer()
		task.delay(3,function() if button and button.Parent and pending then button.Text="Retry Continue" end end)
	end)
	continueButton.Position=UDim2.fromOffset(12,52)
	continueButton.Size=UDim2.new(1,-24,0,46)
	button=continueButton
	UiKit.Focus(continueButton)
end
function Newspaper.Result(result: any)
	if result.command~="ContinueFromNewspaper" then return end
	if result.accepted then Newspaper.Close() else
		pending=false
		if button then button.Text="Try Continue again" end
		Tagline.Show({text=result.reason or "Please try again.",speaker="Next stage",essential=false})
	end
end
return Newspaper
