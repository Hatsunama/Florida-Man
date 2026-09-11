--!strict
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Settings = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Settings"))
local PresentationState = require(script.Parent.Parent.Controllers:WaitForChild("PresentationState"))
local UiKit = {}
local activePanel: ScreenGui? = nil
UiKit.Colors = { background = Color3.fromRGB(19,27,36), panel = Color3.fromRGB(28,39,50), text = Color3.fromRGB(244,242,220), muted = Color3.fromRGB(189,205,215), accent = Color3.fromRGB(255,191,77) }
function UiKit.Corner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 9)
	corner.Parent = parent
end
function UiKit.Text(parent: Instance, text: string, size: number?): TextLabel
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Gotham
	label.TextColor3 = UiKit.Colors.text
	label.TextSize = (size or 16) + (if Settings.GetBool(Players.LocalPlayer,"LargeText") then 3 else 0)
	label:SetAttribute("FM_BaseTextSize",size or 16)
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Text = text
	label.Parent = parent
	return label
end
function UiKit.Button(parent: Instance, text: string, callback: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,48)
	button.BackgroundColor3 = Color3.fromRGB(47,72,90)
	button.TextColor3 = UiKit.Colors.text
	button.Font = Enum.Font.GothamBold
	button.TextSize = if Settings.GetBool(Players.LocalPlayer,"LargeText") then 18 else 15
	button:SetAttribute("FM_BaseTextSize",15)
	button.TextWrapped = true
	button.Text = text
	button.LayoutOrder=#parent:GetChildren()
	button.Active = true
	button.Selectable = true
	button.AutoButtonColor = true
	button.Parent = parent
	UiKit.Corner(button)
	button.Activated:Connect(callback)
	return button
end
function UiKit.Focus(button: GuiObject?)
	if button and UserInputService:GetLastInputType().Name:find("Gamepad") then GuiService.SelectedObject = button end
end
function UiKit.Screen(name: string, order: number): ScreenGui
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild(name)
	if old then old:Destroy() end
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.DisplayOrder = order
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg
	return gui
end
function UiKit.Panel(name: string, title: string, width: number?, modal: boolean?): (ScreenGui, ScrollingFrame)
	if activePanel then activePanel:Destroy(); activePanel=nil end
	local gui = UiKit.Screen(name,60)
	activePanel=gui
	if modal then PresentationState.SetModal(name,true) end
	gui.Destroying:Connect(function()
		if activePanel==gui then activePanel=nil end
		PresentationState.SetModal(name,false)
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
	end)
	local background = Instance.new("Frame")
	background.AnchorPoint = Vector2.new(0.5,0.5)
	background.Position = UDim2.fromScale(0.5,0.5)
	background.Size = UDim2.new(1,-24,1,-32)
	background.BackgroundColor3 = UiKit.Colors.background
	background.Parent = gui
	UiKit.Corner(background,12)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(width or 560,620)
	constraint.Parent = background
	local heading = UiKit.Text(background,title,22)
	heading.Position = UDim2.fromOffset(16,12)
	heading.Size = UDim2.new(1,-32,0,56)
	heading.Font = Enum.Font.GothamBold
	heading.TextColor3 = UiKit.Colors.accent
	local scroll = Instance.new("ScrollingFrame")
	scroll.Position = UDim2.fromOffset(16,76)
	scroll.Size = UDim2.new(1,-32,1,-92)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Parent = background
	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0,8)
	pad.PaddingBottom = UDim.new(0,12)
	pad.Parent = scroll
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,10)
	layout.Parent = scroll
	return gui,scroll
end
ContextActionService:BindAction("FM_ClosePanel",function(_,phase)
	if activePanel and activePanel.Name~="FM_Draft" and phase==Enum.UserInputState.Begin then activePanel:Destroy(); return Enum.ContextActionResult.Sink end
	return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.Escape,Enum.KeyCode.ButtonB)
function UiKit.Paragraph(parent: Instance, text: string): TextLabel
	local label = UiKit.Text(parent,text)
	label.LayoutOrder=#parent:GetChildren()
	label.Size = UDim2.new(1,0,0,0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	return label
end
Players.LocalPlayer:GetAttributeChangedSignal("LargeText"):Connect(function()
	local playerGui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return end
	for _,object in playerGui:GetDescendants() do
		local base=object:GetAttribute("FM_BaseTextSize")
		if typeof(base)=="number" and (object:IsA("TextLabel") or object:IsA("TextButton")) then
			object.TextSize=base+(if Settings.GetBool(Players.LocalPlayer,"LargeText") then 3 else 0)
		end
	end
end)
return UiKit
