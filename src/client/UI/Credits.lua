--!strict
local Remotes=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Remotes"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Tagline=require(script.Parent:WaitForChild("Tagline"))
local Credits={}
local gui: ScreenGui?=nil
local button: TextButton?=nil
local sentAt=-math.huge
function Credits.Close()
 if gui then gui:Destroy(); gui=nil end
 button=nil; sentAt=-math.huge
end
function Credits.Show(payload: any)
 if typeof(payload)~="table" then return end
 Credits.Close()
 Tagline.Show({id="sunrise",text=payload.subtitle or "The swamp gets to stay wild.",speaker="Sunrise",generation=payload.generation,priority=10,scope="run"})
 for index,line in payload.lines or {} do
  if typeof(line)=="string" and line~="" then
   Tagline.Show({id="ending:"..tostring(index),text=line,speaker="Sunrise",generation=payload.generation,priority=10,scope="run"})
  end
 end
 local screen=UiKit.Screen("FM_Credits",45)
 gui=screen
 local panel=Instance.new("Frame")
 panel.AnchorPoint=Vector2.new(0.5,1); panel.Position=UDim2.new(0.5,0,1,-16); panel.Size=UDim2.new(1,-24,0,108)
 panel.BackgroundColor3=UiKit.Colors.background; panel.Parent=screen; UiKit.Corner(panel)
 local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(420,108); limit.Parent=panel
 local title=UiKit.Text(panel,"Adventure complete · Your story is in Notes",16)
 title.Position=UDim2.fromOffset(12,8); title.Size=UDim2.new(1,-24,0,40)
 local close=UiKit.Button(panel,"Return to the bonfire",function()
  if os.clock()-sentAt<2 then return end
  sentAt=os.clock()
  if button then button.Text="Returning…" end
  Remotes.Get("DismissCredits"):FireServer()
  task.delay(3,function() if button and button.Parent then button.Text="Retry return to bonfire" end end)
 end)
 close.Position=UDim2.fromOffset(12,52); close.Size=UDim2.new(1,-24,0,44)
 button=close
 UiKit.Focus(close)
end
function Credits.Result(result: any)
 if result.command~="DismissCredits" then return end
 if result.accepted then Credits.Close()
 else
  sentAt=-math.huge
  if button then button.Text="Try returning again" end
  Tagline.Show({text=result.reason or "Please try again.",speaker="Sunrise",essential=false})
 end
end
return Credits
