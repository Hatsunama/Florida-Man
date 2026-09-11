--!strict
local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local UIS=game:GetService("UserInputService")
local TextService=game:GetService("TextService")
local Settings=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Settings"))
local UiKit=require(script.Parent:WaitForChild("UiKit"))
local Layout=require(script.Parent:WaitForChild("GameplayLayout"))
local Pagination=require(script.Parent:WaitForChild("DialoguePagination"))
local Presentation=require(script.Parent.Parent.Controllers:WaitForChild("PresentationState"))
local Input=require(script.Parent.Parent.Controllers:WaitForChild("InputController"))
local Tagline={}
type Message={text:string,speaker:string?,id:string?,generation:number?,priority:number?,essential:boolean?,scope:string?}
type Beat={text:string,boundaries:{number},speaker:string,generation:number?,priority:number,order:number,essential:boolean,scope:string?}
local queue: {Beat}={}
local seen: {[string]:boolean}={}
local history: {{speaker:string,text:string}}={}
local generation: number?=nil
local phase: string?=nil
local gui: ScreenGui?=nil
local current: Beat?=nil
local body: TextLabel?=nil
local button: TextLabel?=nil
local speakerLabel: TextLabel?=nil
local panel: TextButton?=nil
local lastWidth,lastHeight,lastFontSize=0,0,0
local pageStart,pageEnd,pageLength=1,0,0
local pageReady=false
local revealAt=0
local expires=math.huge
local serial=0
local obscured=false
function Tagline.SetObscured(value: boolean) obscured=value end
local function rect(): Layout.Rect?
 local camera=workspace.CurrentCamera
 if not camera or camera.ViewportSize.X<=0 or camera.ViewportSize.Y<=0 then return nil end
 local inset,tail=GuiService:GetGuiInset()
 local size=camera.ViewportSize-inset-tail
 if size.X<=0 or size.Y<=0 then return nil end
 return Layout.Dialogue(size.X,size.Y,Settings.GetBool(Players.LocalPlayer,"LargeText"),Input.UsesTouch())
end
local function count(text: string): number
 local total=0
 for _first,_last in utf8.graphemes(text) do total+=1 end
 return total
end
local function layout()
 local bubble,message,beat=panel,body,current
 if not bubble or not message or not beat then return end
 local area=rect()
 if not area or area.width<=24 or area.height<=0 then bubble.Visible=false; return end
 bubble.Position=UDim2.fromOffset(area.x,area.y); bubble.Size=UDim2.fromOffset(area.width,area.height)
 local showSpeaker=area.height>=90
 if speakerLabel then speakerLabel.Visible=showSpeaker end
 local width=area.width-24
 local height=area.height-(if showSpeaker then 54 else 36)
 message.Position=UDim2.fromOffset(12,if showSpeaker then 26 else 8)
 message.Size=UDim2.new(1,-24,1,if showSpeaker then -54 else -36)
 local actual=message.AbsoluteSize
 if Presentation.IsModal() or obscured or not gui or not gui.Enabled or height<=0
  or actual.X<=0 or actual.Y<=0 or math.abs(actual.X-width)>1 or math.abs(actual.Y-height)>1 then
  bubble.Visible=false; return
 end
 local fontSize=message.TextSize
 if not pageReady or lastWidth~=actual.X or lastHeight~=actual.Y or lastFontSize~=fontSize then
  local revealed=if pageReady then (if message.MaxVisibleGraphemes<0 then pageLength else math.min(pageLength,message.MaxVisibleGraphemes)) else 0
  local text,finish=Pagination.Page(beat.text,pageStart,beat.boundaries,function(value: string): boolean
   local size=TextService:GetTextSize(value,fontSize,message.Font,Vector2.new(actual.X,10000))
   return size.Y<=actual.Y and size.X<=actual.X
  end)
  if not text then bubble.Visible=false; return end
  pageEnd=finish; pageLength=count(text); pageReady=true
  message.Text=text; message.MaxVisibleGraphemes=math.min(revealed,pageLength)
  revealAt=os.clock()-message.MaxVisibleGraphemes*Settings.TypewriterDelay(Players.LocalPlayer)
  expires=math.huge
  lastWidth,lastHeight,lastFontSize=actual.X,actual.Y,fontSize
  if button then button.Text="Tap or T / ↑ to reveal" end
 end
 bubble.Visible=true
end
local function nextLine()
 if gui then gui:Destroy(); gui=nil end
 current=nil; body=nil; button=nil; panel=nil; speakerLabel=nil
 lastWidth,lastHeight,lastFontSize=0,0,0
 pageStart,pageEnd,pageLength=1,0,0; pageReady=false
 revealAt=os.clock(); expires=math.huge
 while #queue>0 do
  local item=table.remove(queue,1)
  if not item then break end
  if item.scope=="run" or item.generation==nil or generation==nil or item.generation==generation then current=item; break end
 end
 local beat=current
 if not beat then return end
 local screen=UiKit.Screen("FM_Dialogue",35)
 gui=screen
 local bubble=Instance.new("TextButton")
 bubble.Text=""; bubble.AutoButtonColor=false; bubble.Active=true; bubble.Selectable=false; bubble.Visible=false
 bubble.Activated:Connect(function() Tagline.Advance() end)
 bubble.BackgroundColor3=UiKit.Colors.background; bubble.BackgroundTransparency=0.06; bubble.Parent=screen
 panel=bubble; UiKit.Corner(bubble,10)
 local speaker=UiKit.Text(bubble,beat.speaker,14)
 speaker.Position=UDim2.fromOffset(12,6); speaker.Size=UDim2.new(1,-24,0,18); speaker.TextColor3=UiKit.Colors.accent; speakerLabel=speaker
 local message=UiKit.Text(bubble,"",16)
 message.MaxVisibleGraphemes=0; body=message
 local advance=UiKit.Text(bubble,"Tap or T / ↑ to reveal",12)
 advance.Position=UDim2.new(0,12,1,-22); advance.Size=UDim2.new(1,-24,0,18); advance.TextColor3=UiKit.Colors.muted; button=advance
 layout()
end
local function nextPage()
 local beat=current
 if not beat or not pageReady then return end
 if pageEnd>=#beat.text then nextLine(); return end
 -- Only advancing consumes text; resize reflows from the same unacknowledged page start.
 pageStart=pageEnd+1; pageEnd=pageStart-1; pageLength=0; pageReady=false
 revealAt=os.clock(); expires=math.huge
 if body then body.Text=""; body.MaxVisibleGraphemes=0 end
 layout()
end
function Tagline.Advance()
 layout()
 local text,beat,bubble=body,current,panel
 if not text or not beat or not bubble or not bubble.Visible or not pageReady then return end
 if Presentation.IsModal() or obscured then return end
 if text.MaxVisibleGraphemes>=0 then
  text.MaxVisibleGraphemes=-1
  expires=os.clock()+math.max(if beat.essential then 6 else 4,pageLength/10)
  if button then button.Text="Tap or T / ↑ · Next · Saved in Notes" end
 else nextPage() end
end
function Tagline.SetGeneration(value: number?,nextPhase: string?)
 if value==generation then return end
 local resetRun=nextPhase=="Hub" or nextPhase=="Dead" or nextPhase=="Closing" or phase=="Hub"
 generation=value; phase=nextPhase
 if resetRun then table.clear(seen) end
 for index=#queue,1,-1 do
  local beat=queue[index]
  if (resetRun and beat.generation~=value) or (beat.scope~="run" and beat.generation~=nil and beat.generation~=value) then table.remove(queue,index) end
 end
 if current and ((resetRun and current.generation~=value) or (current.scope~="run" and current.generation~=nil and current.generation~=value)) then nextLine() end
end
function Tagline.Show(value: any,speaker: string?)
 local item: Message
 if typeof(value)=="table" then
  if typeof(value.text)~="string" then return end
  item={text=value.text,speaker=value.speaker,id=value.id,generation=value.generation,priority=value.priority,essential=value.essential,scope=value.scope}
 elseif typeof(value)=="string" then item={text=value,speaker=speaker}
 else return end
 if item.text=="" or not utf8.len(item.text) then return end
 if item.generation~=nil and generation~=nil and item.generation<generation then return end
 local key=tostring(item.id or item.text)..":"..(if item.scope=="run" then "run" else tostring(item.generation or generation))
 if item.essential~=false or item.id then
  if seen[key] then return end
  seen[key]=true
 end
 serial+=1
 local boundaries: {number}={}
 for _first,last in utf8.graphemes(item.text) do table.insert(boundaries,last) end
 local beat: Beat={text=item.text,boundaries=boundaries,speaker=item.speaker or speaker or "Captain Steve",generation=item.generation or generation,priority=item.priority or 0,order=serial,essential=item.essential~=false,scope=item.scope}
 table.insert(history,{speaker=beat.speaker,text=beat.text})
 if #history>160 then table.remove(history,1) end
 table.insert(queue,beat)
 -- Incidental notifications may be coalesced. Accepted essential dialogue is retained in field notes across transitions.
 while #queue>64 do
  local remove: number?=nil
  for index=#queue,1,-1 do if not queue[index].essential then remove=index; break end end
  if not remove then break end
  table.remove(queue,remove)
 end
 table.sort(queue,function(a,b) return if a.priority==b.priority then a.order<b.order else a.priority>b.priority end)
 if not current then nextLine() end
end
function Tagline.History(): {{speaker:string,text:string}} return table.clone(history) end
function Tagline.IsActive(): boolean return current~=nil end
CAS:BindAction("FM_DialogueAdvance",function(_,state)
 if Presentation.IsModal() or obscured or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
 if current and panel and panel.Visible and state==Enum.UserInputState.Begin then Tagline.Advance(); return Enum.ContextActionResult.Sink end
 return Enum.ContextActionResult.Pass
end,false,Enum.KeyCode.T,Enum.KeyCode.DPadUp)
Players.LocalPlayer:GetAttributeChangedSignal("LargeText"):Connect(layout)
RunService.Heartbeat:Connect(function(dt)
 if not current or not body then return end
 layout()
 local beat,text,bubble=current,body,panel
 if not beat or not text then return end
 if not pageReady or not bubble or not bubble.Visible then
  revealAt+=dt; if expires<math.huge then expires+=dt end; return
 end
 if text.MaxVisibleGraphemes>=0 then
  local delay=Settings.TypewriterDelay(Players.LocalPlayer)
  local reveal=if delay==0 then pageLength else math.floor((os.clock()-revealAt)/delay)
  text.MaxVisibleGraphemes=math.min(pageLength,reveal)
  if reveal>=pageLength then Tagline.Advance() end
 elseif os.clock()>=expires then nextPage() end
end)
return Tagline
