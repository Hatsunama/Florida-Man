--!strict
--[[ Enemy catalog — cartoon violence only. Enemies poof / ragdoll. Turtles are allies. ]]

local Enemies = {}

export type EnemyDef = {
	id: string,
	name: string,
	hp: number,
	damage: number,
	speed: number,
	color: Color3,
	accent: Color3,
	size: Vector3,
	telegraph: number,
	attackCooldown: number,
	isBoss: boolean,
	isMiniboss: boolean,
	isAlly: boolean,
	dropsPersona: string?,
	dropsItem: string?,
	flavor: string,
	shape: string, -- block | crab | gator | lizard | snake | slime | humanoid | boss
}

local list: { EnemyDef } = {
	{
		id = "BeachCrab", name = "Beach Crab", hp = 28, damage = 6, speed = 10,
		color = Color3.fromRGB(200, 50, 50), accent = Color3.fromRGB(255, 200, 200),
		size = Vector3.new(3.2, 1.6, 3.2), telegraph = 0.45, attackCooldown = 1.4,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Stole your Cold One. Will deny everything.", shape = "crab",
	},
	{
		id = "AngryTourist", name = "Angry Tourist", hp = 40, damage = 8, speed = 9,
		color = Color3.fromRGB(255, 210, 160), accent = Color3.fromRGB(80, 140, 200),
		size = Vector3.new(2.4, 5, 2), telegraph = 0.5, attackCooldown = 1.6,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "IHeartFLShirt",
		flavor = "Lost in the gas station. Taking it personally.", shape = "humanoid",
	},
	{
		id = "SlushieSlime", name = "Slushie Slime", hp = 34, damage = 7, speed = 7,
		color = Color3.fromRGB(255, 60, 160), accent = Color3.fromRGB(120, 255, 255),
		size = Vector3.new(3.5, 2.5, 3.5), telegraph = 0.55, attackCooldown = 1.8,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "GasStationTaquito",
		flavor = "Floor is sticky. So is justice.", shape = "slime",
	},
	{
		id = "DriveThruGator", name = "Drive-Thru Gator", hp = 160, damage = 14, speed = 8,
		color = Color3.fromRGB(45, 110, 55), accent = Color3.fromRGB(180, 160, 40),
		size = Vector3.new(7, 3.2, 3.5), telegraph = 0.7, attackCooldown = 2.0,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = "GatorHauler", dropsItem = "RadioCollar",
		flavor = "Wearing a radio collar. Science experiment gone wrong.", shape = "gator",
	},
	{
		id = "Cottonmouth", name = "Cottonmouth", hp = 32, damage = 9, speed = 14,
		color = Color3.fromRGB(60, 80, 50), accent = Color3.fromRGB(240, 240, 220),
		size = Vector3.new(4, 1.2, 1.2), telegraph = 0.35, attackCooldown = 1.2,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = "SnakeCharmer", dropsItem = nil,
		flavor = "Hisses in lowercase.", shape = "snake",
	},
	{
		id = "OilGator", name = "Oil Gator", hp = 70, damage = 12, speed = 8,
		color = Color3.fromRGB(25, 35, 30), accent = Color3.fromRGB(40, 80, 30),
		size = Vector3.new(6, 2.8, 3), telegraph = 0.65, attackCooldown = 1.7,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "SpillAbsorbent",
		flavor = "Sludge armor. GulfGulp property. Radio collar beeping.", shape = "gator",
	},
	{
		id = "FireLizard", name = "Fire Lizard", hp = 48, damage = 11, speed = 12,
		color = Color3.fromRGB(255, 90, 20), accent = Color3.fromRGB(255, 220, 60),
		size = Vector3.new(3.5, 2.2, 4), telegraph = 0.5, attackCooldown = 1.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = "LizardBreath", dropsItem = nil,
		flavor = "Breathes cartoon fire. HR not notified.", shape = "lizard",
	},
	{
		id = "GulfGulpGrunt", name = "GulfGulp Grunt", hp = 55, damage = 10, speed = 10,
		color = Color3.fromRGB(50, 50, 60), accent = Color3.fromRGB(255, 180, 0),
		size = Vector3.new(2.6, 5.2, 2.2), telegraph = 0.5, attackCooldown = 1.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "Corporate mascot energy. Bad for turtles.", shape = "humanoid",
	},
	{
		id = "MutantAdd", name = "Mutant Add", hp = 45, damage = 9, speed = 11,
		color = Color3.fromRGB(80, 200, 60), accent = Color3.fromRGB(255, 100, 0),
		size = Vector3.new(3, 3, 3), telegraph = 0.4, attackCooldown = 1.3,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Anything is possible in the swamp I guess.", shape = "lizard",
	},
	{
		id = "Spillfather", name = "The Spillfather", hp = 520, damage = 18, speed = 7,
		color = Color3.fromRGB(20, 25, 30), accent = Color3.fromRGB(255, 140, 0),
		size = Vector3.new(12, 8, 6), telegraph = 0.85, attackCooldown = 2.2,
		isBoss = true, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "CEO of sludge. Final headline.", shape = "boss",
	},
	{
		id = "RescueTurtle", name = "Baby Turtle", hp = 9999, damage = 0, speed = 4,
		color = Color3.fromRGB(80, 160, 100), accent = Color3.fromRGB(200, 255, 180),
		size = Vector3.new(2, 1.2, 2.4), telegraph = 0, attackCooldown = 99,
		isBoss = false, isMiniboss = false, isAlly = true, dropsPersona = "TurtlePaladin", dropsItem = "TurtleSticker",
		flavor = "Always an ally. Never harm.", shape = "block",
	},
	{
		id = "CrabKingBoss", name = "Crab King", hp = 120, damage = 11, speed = 9,
		color = Color3.fromRGB(180, 30, 40), accent = Color3.fromRGB(255, 220, 100),
		size = Vector3.new(5.5, 3, 5.5), telegraph = 0.6, attackCooldown = 1.5,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = "CrabKing", dropsItem = "LiveBait",
		flavor = "Cold One hoarder. Sideways royalty.", shape = "crab",
	},
}

Enemies.List = list
Enemies.ById = {} :: { [string]: EnemyDef }
for _, e in list do
	Enemies.ById[e.id] = e
end

function Enemies.Get(id: string): EnemyDef?
	return Enemies.ById[id]
end

return Enemies
