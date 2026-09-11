--!strict
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local LoadingGui={}
local gui: ScreenGui?=nil
local label: TextLabel?=nil
function LoadingGui.Init()
	gui=UiKit.Screen("FM_Loading",100)
	local bg=Instance.new("Frame")
	bg.Size=UDim2.fromScale(1,1)
	bg.BackgroundColor3=UiKit.Colors.background
	bg.Parent=gui
	local title=UiKit.Text(bg,"FLORIDA MAN",32)
	title.Position=UDim2.new(0,24,0.35,0)
	title.Size=UDim2.new(1,-48,0,60)
	title.TextXAlignment=Enum.TextXAlignment.Center
	title.Font=Enum.Font.GothamBlack
	title.TextColor3=UiKit.Colors.accent
	local message=UiKit.Text(bg,"Finding the bonfire…",18)
	message.Position=UDim2.new(0,24,0.5,0)
	message.Size=UDim2.new(1,-48,0,100)
	message.TextXAlignment=Enum.TextXAlignment.Center
	label=message
	task.delay(12,function() if label and label.Parent then label.Text="Still connecting. Your game will begin when the island is ready." end end)
end
function LoadingGui.Ready()
	if gui then gui:Destroy(); gui=nil end
	label=nil
end
return LoadingGui
