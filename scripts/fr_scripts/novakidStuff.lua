--[[
	Provides a variety of effects designed for use by the Novakid race.
	Arguments:

	"args" : {
		"daytimeConfig" : {
			"stats" : [                  -- Applied during the day
				{ "stat" : "energyRegenPercentageRate", "baseMultiplier" : 1.20 },
				...
			],
			"hungerRegen" : 0.008,       -- Hunger% gained/s during the day
			"hungerThreshold" : 0.40,    -- Hunger% required for regen to start
			"maxHunger" : 0.85,          -- Maximum hunger level for regen (stops increasing here, keeps regenning above this)
			"minHunger" : 0.50,          -- Minimum hunger level for regen (starts here, no regen below this)
			"maxRegen" : 0.015,          -- Regen/s at maximum hunger level
			"minRegen" : 0.010,          -- Regen/s at minimum hunger level
		},
		"nightConfig" : {
			"stats" : [                  -- Applied at night
				{ "stat" : "maxEnergy", "baseMultiplier" : 0.75 },
				...
			],
			"hungerThreshold" : 0.5,     -- Hunger% at which regeneration is allowed at night
			"hungerLoss" : -0.0005,      -- Hunger%/s lost at night
			"regen" : 0.010              -- Health%/s gained at night
		}
	}
]]

function FRHelper:call(args, main, dt, ...)
	local hungerEnabled = status.isResource("food")
	local hungerPerc
	if hungerEnabled then
		hungerPerc = status.resourcePercentage("food")
	else
		hungerPerc = 0.85
	end

	local daytime = world.timeOfDay() < 0.5

	-- Night penalties
	if not daytime then
		local nightConfig = args.nightConfig
		self:clearPersistent("FR_novakidDaytime")
		self:applyStats(nightConfig, "FR_novakidNight", main, dt, ...)
		if hungerPerc > nightConfig.hungerThreshold and status.resourcePercentage("health") < 1.0 then
			if hungerEnabled then
				status.modifyResourcePercentage("food", nightConfig.hungerLoss * dt)
			end
			status.modifyResourcePercentage("health", nightConfig.regen * dt * math.max(0,1+status.stat("healingBonus")))
		end
	else
	-- Daytime Abilities
		local dayConfig = args.daytimeConfig
		self:clearPersistent("FR_novakidNight")
		self:applyStats(dayConfig, "FR_novakidDaytime", main, dt, ...)

		local hungerCalc = math.min(1, (hungerPerc - dayConfig.minHunger) / (dayConfig.maxHunger - dayConfig.minHunger))
		local regenCalc = (dayConfig.maxRegen - dayConfig.minRegen) * hungerCalc + dayConfig.minRegen

		--special handling for NPCs, to prevent immortality
		if not (world.isNpc(entity.id()) and status.resource("health") < 1) then
			if hungerPerc >= dayConfig.minHunger then
				status.modifyResourcePercentage("health", regenCalc * dt * math.max(0,1+status.stat("healingBonus")))
			end
		else
			status.setResource("health",0)
		end
	end
end
