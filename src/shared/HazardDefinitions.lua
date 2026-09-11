--!strict
-- Definitions own hazard rules; world builders supply geometry and visuals.
export type HazardDef = {
	slow: ('oil' | 'environment')?, water: boolean?, damage: number?, period: number?, duty: number?, oilResist: boolean?,
	impulseY: number?, velocityX: number?, velocityY: number?,
}
local definitions: { [string]: HazardDef } = {
	oilSlick = { slow = 'oil' }, sandSlow = { slow = 'environment' }, redTide = { slow = 'environment' },
	canalWater = { water = true, slow = 'environment' },
	slushPuddle = { damage = 3, period = 2.4, duty = 0.45 },
	fryerOil = { damage = 5, period = 2.2, duty = 0.42, oilResist = true },
	pipeSpray = { damage = 6, period = 2.4, duty = 0.4, impulseY = 28, oilResist = true },
	slickRing = { damage = 7, period = 3.2, duty = 0.3, oilResist = true },
	movingSample = { damage = 5 }, fireCone = { damage = 4 }, hoaCone = { damage = 4 },
	conveyor = { velocityX = 8 }, windPush = { velocityX = 9, velocityY = -4 },
}
return definitions
