--!strict
-- Presentation classification uses the same hazard definition supplied to the server.
local Rules={}
export type Definition={damage:number?,velocityX:number?,velocityY:number?,slow:('oil'|'environment')?,water:boolean?}
function Rules.Cue(definition: Definition?,enabled: boolean,active: boolean,attack: boolean): string?
	if not enabled then return nil end
	if attack then return "danger" end
	if not definition then return nil end
	if definition.damage then return if active then "danger" else nil end
	if definition.velocityX or definition.velocityY then return "flow" end
	if definition.slow or definition.water then return "slow" end
	return nil
end
return Rules
