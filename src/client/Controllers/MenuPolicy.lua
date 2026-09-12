--!strict
-- Pure rules shared by the HUD lifecycle and controller input router.
local MenuPolicy = {}
function MenuPolicy.CloseForState(old: any, value: any): boolean
	if value.phase=="Dead" or value.phase=="Ending" or value.phase=="Closing" or value.phase=="Loading" then return true end
	if value.runActive and ((value.hp or 0)<=0 or value.characterReady~=true) then return true end
	return old~=nil and (old.generation~=value.generation or old.phase~=value.phase or old.stageId~=value.stageId
		or old.inHub~=value.inHub or old.runActive~=value.runActive)
end
function MenuPolicy.ControllerUIOwnsMovement(modal: boolean, selected: boolean, gameplayMenuSelection: boolean): boolean
	return modal or (selected and not gameplayMenuSelection)
end
return MenuPolicy
