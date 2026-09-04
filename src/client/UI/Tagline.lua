--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Tagline = {}

function Tagline.Show(text: string, speaker: string?)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Tagline")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Tagline"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.7, 0, 0, 96)
	frame.Position = UDim2.new(0.15, 0, 0.72, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	frame.BackgroundTransparency = 0.15
	frame.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = frame
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 200, 80)
	st.Thickness = 2
	st.Parent = frame

	local who = Instance.new("TextLabel")
	who.Size = UDim2.new(1, -24, 0, 22)
	who.Position = UDim2.new(0, 12, 0, 8)
	who.BackgroundTransparency = 1
	who.Font = Enum.Font.GothamBold
	who.TextSize = 14
	who.TextXAlignment = Enum.TextXAlignment.Left
	who.TextColor3 = Color3.fromRGB(255, 190, 70)
	who.Text = (speaker or "Captain Steve") .. " — live from the swamp"
	who.Parent = frame

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -24, 0, 54)
	body.Position = UDim2.new(0, 12, 0, 32)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamBold
	body.TextWrapped = true
	body.TextSize = 20
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(255, 245, 220)
	body.Text = ""
	body.Parent = frame

	frame.BackgroundTransparency = 1
	TweenService:Create(frame, TweenInfo.new(0.35), { BackgroundTransparency = 0.15 }):Play()

	local full = '"' .. text .. '"'
	local cancelled = false
	gui.Destroying:Connect(function()
		cancelled = true
	end)
	task.spawn(function()
		for i = 1, #full do
			if cancelled or not gui.Parent then
				return
			end
			body.Text = string.sub(full, 1, i)
			task.wait(0.028)
		end
	end)

	task.delay(6.2, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

return Tagline
