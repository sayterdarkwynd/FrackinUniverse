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
	self:clearPersistent("FR_spirittreeDaytime")
	self:clearPersistent("FR_spirittreeNight")

	self:clearPersistent("FR_spirittreeStuff")
	self:applyStats(((world.timeOfDay() or 0) < 0.5) and args.daytimeConfig or args.nightConfig, "FR_spirittreeStuff", main, dt, ...)
end