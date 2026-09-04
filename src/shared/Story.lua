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

-- N5: first MidGate lock Tagline per act (popup-only)
Story.MIDGATE_LOCK = {
	[1] = "ROOM LOCK — clear the wave. The boardwalk doesn't negotiate.",
	[2] = "ROOM LOCK — swamp gate sealed. Clear hostiles; pads still matter.",
	[3] = "ROOM LOCK — nests behind the barrier. Clear it, then escort turtles.",
	[4] = "ROOM LOCK — GulfGulp airlock. Conveyors flip. Clear the wave.",
	[5] = "ROOM LOCK — last checkpoint before the Spillfather. No empty-wave cheese.",
}

Story.VERB_TOAST = {
	hangoverColdOne = "VERB: Hangover slows you — walk into the Cold One (Florida Dew).",
	timedRhythm = "VERB: Timed hazards — jump when the puddle goes HOT.",
	padWater = "VERB: Pad-only — deep water soft-falls you if you linger.",
	oilSlick = "VERB: Oil slicks slow hard — skim the edges or slip.",
	turtleEscort = "VERB: Stay near turtles — they walk toward the nest. Press E to rescue.",
	midGate = "VERB: MidGate rooms — step in, clear the wave, path opens.",
	conveyorFlip = "VERB: Conveyors flip direction on a timer — read the arrows.",
	windGaps = "VERB: Jump the gaps — wind cuts your jump if you linger in the gust.",
	bossArena = "VERB: Boss telegraphs denser — clear adds; empty MidGate never locks.",
}


-- Act 1 event-tied Steve lines (not random rotate)
Story.ACT1_EVENTS = {
	coldOne = "Florida Dew acquired. Comedy's still running — listen for the beep under the cooler later.",
	collarHint = "You hear that? Radio collars. That's not wildlife. That's a logo with teeth.",
	afterColdOneHub = "Kid, you got the Cold One back. Bonfire's proud. The swamp won't be.",
}


-- Comic / newspaper interstitial art panels (colored Frames + beat text)
Story.NEWSPAPER_PANELS = {
	[1] = {
		{ title = "COLD ONE", text = "Comedy first. Reclaim the Florida Dew.", color = { 70, 160, 220 } },
		{ title = "COLLAR BEEP", text = "Radio collars under tourist coolers. Unease begins.", color = { 255, 140, 40 } },
		{ title = "DRIVE-THRU", text = "A gator refuses to supersize. The logo has teeth.", color = { 255, 80, 40 } },
	},
	[2] = {
		{ title = "SWAMP", text = "It IS Florida… Anything is possible in the swamp.", color = { 80, 160, 60 } },
		{ title = "NOT WILD", text = "Animals aren't the enemy. Someone sold them as security.", color = { 40, 100, 50 } },
		{ title = "GULFGULP", text = "'Wildlife enhancement' = crime with a PR budget.", color = { 120, 80, 40 } },
	},
	[3] = {
		{ title = "RED TIDE", text = "Their cleanup is a cover. Nests get oiled on purpose.", color = { 180, 40, 70 } },
		{ title = "RESCUE", text = "Turtles are allies. Always. You rescue them or you don't leave.", color = { 100, 255, 180 } },
		{ title = "SHELL UP", text = "Justice smells like salt and sunscreen.", color = { 255, 200, 100 } },
	},
	[4] = {
		{ title = "LAB FILE", text = "Engineered gators to guard spills. Read that again.", color = { 80, 220, 120 } },
		{ title = "PIPES", text = "Every corridor is a confession.", color = { 90, 90, 110 } },
		{ title = "BADGE", text = "AUTHORIZED — pelican testimony says otherwise.", color = { 255, 180, 40 } },
	},
	[5] = {
		{ title = "BARGE", text = "Real gaps. Soft checkpoints. Keep the nests.", color = { 60, 90, 120 } },
		{ title = "SPILLFATHER", text = "Middle management with a sludge mech. Refuse the bargain.", color = { 255, 140, 20 } },
		{ title = "SUNRISE", text = "For the turtles. For the swamp that gets to stay wild.", color = { 255, 220, 120 } },
	},
}

function Story.NewspaperPanels(act: number): { any }
	local a = math.clamp(act, 1, 5)
	return Story.NEWSPAPER_PANELS[a] or Story.NEWSPAPER_PANELS[1]
end

function Story.SteveEventLine(eventId: string): string?
	return Story.ACT1_EVENTS[eventId]
end

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

function Story.MidGateLockLine(act: number): string
	return Story.MIDGATE_LOCK[math.clamp(act, 1, 5)] or Story.MIDGATE_LOCK[1]
end

function Story.VerbToast(verb: string): string?
	return Story.VERB_TOAST[verb]
end

return Story
