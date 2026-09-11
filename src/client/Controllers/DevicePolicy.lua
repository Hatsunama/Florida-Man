--!strict
local Device={}
function Device.Cohort(lastInput: string,touch: boolean,keyboard: boolean,gamepad: boolean): string
	if string.find(lastInput,"Gamepad",1,true) then return "gamepad" end
	if lastInput=="Touch" then return "touch" end
	if lastInput=="Keyboard" or string.find(lastInput,"Mouse",1,true) then return "keyboard" end
	if touch and not keyboard then return "touch" end
	if gamepad and not keyboard then return "gamepad" end
	return "keyboard"
end
return Device
