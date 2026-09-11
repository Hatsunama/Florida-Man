local L=require("../src/client/UI/GameplayLayout")
local cases={{320,256},{360,640},{568,284},{640,324},{810,536},{1280,684}}
local checked=0
for _,size in cases do
	for _,large in {false,true} do
		for _,touch in {false,true} do
			local hud=L.Hud(size[1]); local text=L.Dialogue(size[1],size[2],large,touch)
			assert(not L.Overlaps(hud,text),"dialogue must not cover persistent status")
			assert(text.x>=0 and text.x+text.width<=size[1] and text.y+text.height<=size[2],"popup stays within content viewport")
			if touch then assert(not L.Overlaps(text,L.TouchControls(size[1],size[2])),"dialogue must not cover touch controls") end
			checked+=1
		end
	end
end
assert(L.Dialogue(320,180,true,true).height==0,"defer popup when all controls and text cannot fit")
print("PASS: "..checked.." production HUD/dialogue/touch viewport configurations plus constrained-height fallback")
