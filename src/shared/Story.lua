--!strict
--[[ Campaign copy: Steve banter per act, hub headlines, death cards, credits. ]]

local Story = {}

Story.ACTS = {
	[1] = {
		name = "Hangover Coast",
		steve = {
			"Kid, the crabs took your Cold One. That's the joke. The swamp tells the truth later.",
			"Radio collars on gators? That's not 'nature.' That's a logo with teeth.",
			"Press E at the bonfire (or click the prompt) when you're ready to chase a headline across half the state.",
		},
	},
	[2] = {
		name = "The Swamp That Isn't Wild",
		steve = {
			"It IS Florida… Anything is possible in the swamp I guess.",
			"Those animals aren't the enemy. Someone sold them as security.",
			"GulfGulp calls it 'wildlife enhancement.' I call it a crime with a PR budget.",
		},
	},
	[3] = {
		name = "Red Tide Bargain",
		steve = {
			"Their 'cleanup' is a cover. The nests get oiled so pipelines can claim no habitat.",
			"Turtles are allies. Always. You rescue them or you don't leave.",
			"Shell up. Justice smells like salt and sunscreen.",
		},
	},
	[4] = {
		name = "Inside GulfGulp",
		steve = {
			"Lab files say they engineered the gators to guard spills. Read that again.",
			"Pipes, docks, barges — every corridor is a confession.",
			"The Spillfather is waiting. He's middle management with a sludge mech.",
		},
	},
	[5] = {
		name = "The Spillfather",
		steve = {
			"Save what's left of the nests. Then watch the sun come up like a punchline.",
			"You danced until the fire died. Now you dance until the swamp lives.",
			"It IS Florida… and somehow you made it better.",
		},
	},
}

Story.HUB_FIRST = "FLORIDA MAN — you danced until the fire died. The crabs stole your Cold One."
Story.HUB_AFTER_DEATH = "LOCAL LEGEND RETURNS TO BONFIRE — experts cite unfinished business and one missing Florida Dew"

Story.DEATH_LINES = {
	"You poofed into a headline. The bonfire still knows your name.",
	"GulfGulp didn't win. You just need another Cold One and worse judgment.",
	"Captain Steve rearranges the lawn chairs. 'Again?' he asks. Yes. Again.",
}

Story.CREDITS = {
	"The swamp exhales.",
	"Radio collars go quiet.",
	"Baby turtles hit the tide like tiny lawsuits against evil.",
	"",
	"GulfGulp Energy stock: down.",
	"The Spillfather: recycled into parody.",
	"",
	"Captain Steve (pelican):",
	"It IS Florida… Anything is possible in the swamp I guess.",
	"",
	"You wake on the beach again someday.",
	"But tonight the Cold One is yours,",
	"and the sunrise is actually trying.",
	"",
	"Thanks for playing — Press E at the bonfire to run it back.",
}

function Story.SteveLine(act: number, deaths: number?): string
	local a = Story.ACTS[math.clamp(act, 1, 5)]
	if not a then
		return Story.ACTS[1].steve[1]
	end
	local lines = a.steve
	local idx = ((deaths or 0) % #lines) + 1
	return lines[idx]
end

function Story.HubHeadline(deaths: number): string
	if deaths > 0 then
		return Story.HUB_AFTER_DEATH
	end
	return Story.HUB_FIRST
end

function Story.DeathLine(deaths: number): string
	return Story.DEATH_LINES[((deaths - 1) % #Story.DEATH_LINES) + 1]
end

return Story
