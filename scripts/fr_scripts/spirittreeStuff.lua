--[[
	Provides a variety of effects designed for use by the Spirittree race.
	Arguments:
	
	"args" : {
				"daytimeConfig" : {
					"stats" : [                  // Applied during the day
						{ "stat" : "energyRegenPercentageRate", "effectiveMultiplier" : 1.10 }
					]
				},
				"nightConfig" : {
					"stats" : [                  // Applied at night
						{ "stat" : "maxEnergy", "effectiveMultiplier" : 0.85 },
						{ "stat": "powerMultiplier", "effectiveMultiplier": 0.85 },
						{ "stat" : "energyRegenPercentageRate", "effectiveMultiplier" : 1.0 }
					]
				}
			}
	}
]]

function FRHelper:call(args, main, dt, ...)
	
	local daytime = world.timeOfDay() < 0.5
	
	-- Night penalties
	if not daytime then
		local nightConfig = args.nightConfig
		self:clearPersistent("FR_spirittreeDaytime")
		self:applyStats(nightConfig, "FR_spirittreeNight", main, dt, ...)
	else
	-- Daytime Abilities
		local dayConfig = args.daytimeConfig
		self:clearPersistent("FR_spirittreeNight")
		self:applyStats(dayConfig, "FR_spirittreeDaytime", main, dt, ...)
	end
end