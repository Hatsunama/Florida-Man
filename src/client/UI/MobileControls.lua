--!strict
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local State=require(script.Parent.Parent.Controllers:WaitForChild("PresentationState"))
local Mobile={}
function Mobile.Init(input: any)
	local gui=UiKit.Screen("FM_MobileControls",30)
	local holder=Instance.new("Frame")
	holder.Size=UDim2.new(1,0,0,112)
	holder.Position=UDim2.new(0,0,1,-120)
	holder.BackgroundTransparency=1
	holder.Parent=gui
	local active: { [InputObject]: () -> () }={}
	local function release()
		for event,finish in active do finish(); active[event]=nil end
	end
	local function hold(button: TextButton,begin: () -> (),finish: () -> ())
		button.InputBegan:Connect(function(event)
			if event.UserInputType==Enum.UserInputType.Touch or event.UserInputType==Enum.UserInputType.MouseButton1 then active[event]=finish; begin() end
		end)
		button.InputEnded:Connect(function(event)
			if active[event] then active[event](); active[event]=nil end
		end)
	end
	UIS.InputEnded:Connect(function(event) if active[event] then active[event](); active[event]=nil end end)
	local left=UiKit.Button(holder,"←",function() end)
	left.Position=UDim2.new(0,8,1,-50); left.Size=UDim2.fromOffset(50,48)
	hold(left,function() input.Intent("move","begin",-1,"touchLeft") end,function() input.Intent("move","end",0,"touchLeft") end)
	local right=UiKit.Button(holder,"→",function() end)
	right.Position=UDim2.new(0,64,1,-50); right.Size=UDim2.fromOffset(50,48)
	hold(right,function() input.Intent("move","begin",1,"touchRight") end,function() input.Intent("move","end",0,"touchRight") end)
	local jump=UiKit.Button(holder,"JUMP",function() end)
	jump.Position=UDim2.new(0,8,0,4); jump.Size=UDim2.fromOffset(106,48)
	hold(jump,function() input.Intent("jump","begin") end,function() input.Intent("jump","end") end)
	local buttons={}
	local actions={{"ATK","attack"},{"SKILL","skill"},{"DODGE","dodge"},{"SWAP","swap"},{"WPN","weapon"},{"USE","interact"}}
	for index,definition in actions do
		local button=UiKit.Button(holder,definition[1],function() input.Intent(definition[2]) end)
		local column=(index-1)%3
		local row=math.floor((index-1)/3)
		button.Size=UDim2.fromOffset(52,48)
		button.Position=UDim2.new(1,-176+column*56,0,4+row*56)
		button.TextSize=12
		buttons[definition[2]]=button
	end
	input.InteractionChanged:Connect(function(prompt)
		buttons.interact.Text=if prompt then prompt.ActionText else "USE"
	end)
	local function visible()
		local state=State.Get()
		local shown=input.UsesTouch() and state~=nil and (state.phase=="Active" or state.phase=="Hub") and not State.IsModal()
		if not shown and holder.Visible then release() end
		holder.Visible=shown
	end
	State.Changed:Connect(function() task.defer(visible) end)
	UIS.LastInputTypeChanged:Connect(visible)
	UIS.WindowFocusReleased:Connect(release)
	local function tint(button: TextButton,ready: boolean)
		button.BackgroundColor3=if ready then Color3.fromRGB(47,72,90) else Color3.fromRGB(38,44,50)
		button.TextColor3=if ready then UiKit.Colors.text else UiKit.Colors.muted
		button.AutoButtonColor=ready
	end
	local elapsed=0
	local heartbeat=RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt; if elapsed<0.1 then return end; elapsed=0
		if not holder.Visible then return end
		for _,definition in actions do
			local action=definition[2]
			local ready,leftTime,waiting=input.ActionStatus(action)
			local prompt=input.GetInteraction()
			local label=if action=="interact" and prompt then prompt.ActionText else definition[1]
			buttons[action].Text=label..(if waiting then "\n…" elseif leftTime>0.05 then "\n"..string.format("%.1fs",leftTime) elseif not ready then "\n—" else "")
			tint(buttons[action],ready)
		end
		tint(left,input.Can("move")); tint(right,input.Can("move")); tint(jump,input.Can("jump"))
	end)
	gui.Destroying:Connect(function() release(); heartbeat:Disconnect() end)
	visible()
end
return Mobile
