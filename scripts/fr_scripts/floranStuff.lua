--[[
	Provides a variety of effects designed for use by the Floran race.
	Arguments:

	"args" : {
		"daytimeConfig" : {
			"stats" : [                  -- Applied when at full health, full food, and during the day
				{ "stat" : "energyRegenPercentageRate", "amount" : 0.35 },
				...
			],
			"hungerRegen" : 0.008,       -- Hunger% gained/s during the day
			"hungerThreshold" : 0.40,    -- Hunger% required for regen to start
			"maxLight" : 0.95,           -- Maximum light level for regen (stops increasing here, keeps regenning above this)
			"minLight" : 0.25,           -- Minimum light level for regen (starts here, no regen below this)
			"maxRegen" : 0.003,          -- Regen/s at maximum light level
			"minRegen" : 0.001,          -- Regen/s at minimum light level
			"undergroundLight" : 0.60,   -- Minimum light required underground
			"undergroundScale" : 0.5     -- Multiplier on normal regen when underground
			"undergroundHunger" : -0.005 -- Food lost when regenerating underground
		},
		"nightConfig" : {
			"stats" : [     -- Applied at night
				{ "stat" : "maxHealth", "baseMultiplier" : 0.90 },
				...
			],
			"hungerLoss" : -0.0032,       -- Hunger% lost/s at night
			"hungerLossLight" : -0.0019,  -- Hunger% lost/s at night, with lightThreshold or more light
			"lightThreshold" : 0.25      -- Threshold for reduced hunger loss at night
		}
	}
]]

function FRHelper:call(args, main, dt, ...)
	local hungerEnabled = status.isResource("food")
	local hungerPerc
	if hungerEnabled then
		hungerPerc = status.resourcePercentage("food")
	else
		hungerPerc = 3.0 / 12
	end

	local daytime = world.timeOfDay() < 0.5
	local lightLevel = math.min(world.lightLevel(mcontroller.position()),1.0)

	-- Night penalties
	if not daytime then
		local nightConfig = args.nightConfig

		-- Florans lose HP and Energy when the sun is not out
		self:applyPersistent(nightConfig.stats, "FR_floranNight")
		self:clearPersistent("FR_floranDaytime")

		-- when the sun is down, florans lose food
		if hungerEnabled and hungerPerc < 1.0 then
			--reduce the hunger drain if bathed in light
			if lightLevel > nightConfig.lightThreshold then --you can reduce the drain with light
				status.modifyResourcePercentage("food", nightConfig.hungerLossLight * dt)
			else
			-- otherwise we lose normal amount
				status.modifyResourcePercentage("food", nightConfig.hungerLoss * dt)
			end
		end
	else
	-- Daytime Abilities
		local underground = world.underground(mcontroller.position())
		local dayConfig = args.daytimeConfig

		self:clearPersistent("FR_floranNight")
		-- when a floran is in the sun, has full health and full food, their energy regen rate increases
		if (hungerPerc >= 0.98) and status.resourcePercentage("health") >= 0.98 then
			self:applyPersistent(dayConfig.stats, "FR_floranDaytime")
		else
			self:clearPersistent("FR_floranDaytime")
		end

		-- when the sun is out, florans regenerate food
		if hungerEnabled and hungerPerc < 1.0 then
			status.modifyResourcePercentage("food", 0.008 * dt)
		end

		local lightCalc = math.min(1, (lightLevel - dayConfig.minLight) / (dayConfig.maxLight - dayConfig.minLight))
		local regenCalc = (dayConfig.maxRegen - dayConfig.minRegen) * lightCalc + dayConfig.minRegen

		-- When it is sunny and they are well fed, florans regenerate
		--special handling for NPCs, to prevent immortality
		if not (world.isNpc(entity.id()) and status.resource("health") < 1) then
			if hungerPerc >= dayConfig.hungerThreshold and lightLevel > dayConfig.minLight then
				if underground and lightLevel > dayConfig.undergroundLight then
					if hungerEnabled then
						status.modifyResourcePercentage("food", -0.005 * dt)
					end
					regenCalc = regenCalc * dayConfig.undergroundScale
					status.modifyResourcePercentage("health", regenCalc * dt * math.max(0,1+status.stat("healingBonus")))
				elseif not underground and lightLevel > dayConfig.minLight then
					status.modifyResourcePercentage("health", regenCalc * dt * math.max(0,1+status.stat("healingBonus")))
				end
			end
		else
			status.setResource("health",0)
		end
	end
end
