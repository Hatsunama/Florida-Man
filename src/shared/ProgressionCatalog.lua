--!strict
-- Permanent weapon unlocks awarded once per completed stage.
local weaponDrops: { [string]: { string } } = {
		DaytonaHangover = { "FlipFlopSlap", "CoolerLid" },
		BoardwalkChaos = { "PoolNoodle", "NewspaperRoll" },
		GasStationLegends = { "GolfClub", "TrafficCone" },
		StripMallShowdown = { "HOAClipboard", "BeachUmbrella" },
		DriveThruDisaster = { "GatorWrestleGloves", "ShoppingCart" },
		CanalRun = { "KayakPaddle", "WaterBalloonSling" },
		SwampShift = { "SnakeLasso", "FishSmack" },
		CypressCathedral = { "TikiTorch", "LawnDart" },
		SludgeBayou = { "SpillSkimmer" },
		ConspiracyShack = { "Skateboard", "PelicanBeakReplica" },
		TurtleBeach = { "NetGun" },
		GulfGulpGate = { "FireExtinguisher" },
		LabWing = { "BugZapper" },
		PipeGauntlet = { "OilBarrelLid" },
		BargeCrossing = { "BoogieBoard" },
		OilPlatformApproach = { "SludgeHose" },
		HelipadHysteria = { "RomanCandle" },
		GulfGulpRig = { "FinaleRocket" },
	}
return table.freeze(weaponDrops)
