--!strict
--[[ Campaign bible — used by hub board, Steve, newspaper, death cards, credits.
	Every act has a tone, Steve lines (unique, escalate), and emotional beats.
	Newspaper headlines live on Stages; they MUST advance plot (not generic BREAKING).
]]

local Story = {}

Story.ACTS = {
	[1] = {
		name = "Hangover Coast",
		tone = "Comedy headlines → first collar unease",
		steve = {
			"Kid, the crabs took your Cold One. That's the joke. The swamp tells the truth later.",
			"Radio collars on gators? That's not 'nature.' That's a logo with teeth.",
			"Press E at the bonfire (or click the prompt) when you're ready to chase a headline across half the state.",
			"Florida Dew first. Existential dread second. That's the order.",
		},
	},
	[2] = {
		name = "The Swamp That Isn't Wild",
		tone = "Mutants reveal; Steve tagline once, then escalate",
		steve = {
			"It IS Florida… Anything is possible in the swamp I guess.",
			"Those animals aren't the enemy. Someone sold them as security.",
			"GulfGulp calls it 'wildlife enhancement.' I call it a crime with a PR budget.",
			"You heard the tagline. Now listen to the collars beep.",
		},
	},
	[3] = {
		name = "Red Tide Bargain",
		tone = "Turtles; moral turn — cleanup is a cover",
		steve = {
			"Their 'cleanup' is a cover. The nests get oiled so pipelines can claim no habitat.",
			"Turtles are allies. Always. You rescue them or you don't leave.",
			"Shell up. Justice smells like salt and sunscreen.",
			"If you hurt a turtle I will personally rearrange your lawn chair into a lawsuit.",
		},
	},
	[4] = {
		name = "Inside GulfGulp",
		tone = "Lab files; engineered gators; every corridor a confession",
		steve = {
			"Lab files say they engineered the gators to guard spills. Read that again.",
			"Pipes, docks, barges — every corridor is a confession.",
			"The Spillfather is waiting. He's middle management with a sludge mech.",
			"Badge says AUTHORIZED. Pelican testimony says otherwise.",
		},
	},
	[5] = {
		name = "The Spillfather",
		tone = "Personal + funny + earned",
		steve = {
			"Save what's left of the nests. Then watch the sun come up like a punchline.",
			"You danced until the fire died. Now you dance until the swamp lives.",
			"It IS Florida… and somehow you made it better.",
			"Go on. Make the Spillfather regret inventing a job title.",
		},
	},
}

Story.HUB_FIRST = "FLORIDA MAN — you danced until the fire died. The crabs stole your Cold One."
Story.HUB_AFTER_DEATH = {
	"LOCAL LEGEND RETURNS TO BONFIRE — experts cite unfinished business and one missing Florida Dew",
	"FLORIDA MAN SEEN AGAIN — 'I only need one more try,' claims person shaped like regret",
	"BONFIRE STILL LIT — pelican refuses to file missing-person report, cites 'vibes'",
	"SUNBURN STOCK CLIMBS — Florida Man drafts better this time (allegedly)",
	"CRABS ISSUE STATEMENT — 'We kept the Cold One as collateral. Collateral for what? Yes.'",
}

Story.DEATH_LINES = {
	"You poofed into a headline. The bonfire still knows your name.",
	"GulfGulp didn't win. You just need another Cold One and worse judgment.",
	"Captain Steve rearranges the lawn chairs. 'Again?' he asks. Yes. Again.",
	"The turtles send thoughts and snacks. Mostly snacks.",
	"You died doing something Florida. The newspaper will call it 'character development.'",
}

-- Character sendoffs — emotional + funny, used in credits scroll
Story.CREDITS = {
	"The swamp exhales.",
	"Radio collars go quiet.",
	"Baby turtles hit the tide like tiny lawsuits against evil.",
	"",
	"— CAST SENDOFFS —",
	"",
	"Beach Burnout: kept the rhythm. Lost the hangover.",
	"Crab King: returned the Cold One. Kept the sideways swagger.",
	"Drive-Thru Gator: collar cut. Still refuses to supersize.",
	"HOA Binder Karen: cited for excessive clipboard. Appeals pending.",
	"Influencer Stick: flashbanned from the swamp. Ratioed by a pelican.",
	"Collared Oil Gators: free. Still sticky. Healing.",
	"Fire-Breathing Lizards: employed as swamp heaters (unionized).",
	"Baby Turtles: alive. Snacking. Justice-flavored.",
	"",
	"GulfGulp Energy stock: down.",
	"The Spillfather: recycled into parody.",
	"Cheap Hazmat Grunts: seeking better benefits.",
	"",
	"Captain Steve (pelican):",
	"It IS Florida… Anything is possible in the swamp I guess.",
	"",
	"You wake on the beach again someday.",
	"But tonight the Cold One is yours,",
	"and the sunrise is actually trying.",
	"",
	"Thanks for playing — Press E at the bonfire (or click the prompt) to run it back.",
}

Story.ACT_OPENERS = {
	[1] = "Act 1 — Hangover Coast: comedy first. Truth later.",
	[2] = "Act 2 — The Swamp That Isn't Wild: the animals aren't the enemy.",
	[3] = "Act 3 — Red Tide Bargain: rescue is the mission.",
	[4] = "Act 4 — Inside GulfGulp: the memo is the smoking gun.",
	[5] = "Act 5 — The Spillfather: refuse the bargain. For the turtles.",
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
	if deaths <= 0 then
		return Story.HUB_FIRST
	end
	local lines = Story.HUB_AFTER_DEATH
	return lines[((deaths - 1) % #lines) + 1]
end

function Story.DeathLine(deaths: number): string
	return Story.DEATH_LINES[((deaths - 1) % #Story.DEATH_LINES) + 1]
end

function Story.ActOpener(act: number): string
	return Story.ACT_OPENERS[math.clamp(act, 1, 5)] or Story.ACT_OPENERS[1]
end

return Story
