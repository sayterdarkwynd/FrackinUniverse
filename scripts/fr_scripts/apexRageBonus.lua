require("/scripts/vec2.lua")
require("/scripts/util.lua")

--[[
    This script gives a scaling status effect based on health lost.
	The effects increase starting from healthRange[1] and reach their maximum at healthRange[2].
    Arguments:

	"args" : {
		"healthRange" : [0.8, 0.1]   -- % of health when this effect starts and stops increasing
		"stats" : [                  -- Which stats this applies, and their maximum values
			{ "stat" : "maxEnergy", "effectiveMultiplier" : 0.3 },
			{ "stat" : "powerMultiplier", "effectiveMultiplier" : 1.3 },
			...
		]
	}
]]
--[[ commented this all out for the time being, as its no longer in use
function FRHelper:call(args, ...)
	if not args or not args.healthRange then return end

	local healthRange = args.healthRange
	local health = status.resourcePercentage("health")
	if health > healthRange[1] then return end

	-- Scale the current health % to the area of interest
	local healthRelative = math.max(0, (health - healthRange[2]) / (healthRange[1] - healthRange[2]))
	local scale = 1 - healthRelative

	local scaleMultiplier = function (mult, scaleThing)
		if mult >= 1 then
			return 1 + (mult - 1) * scaleThing
		elseif mult < 1 then
			return mult + (1 - mult) * healthRelative
		end
	end

	local stats = util.map(args.stats,
		function (v)
			return {
				stat = v.stat,
				amount = v.amount and v.amount * scale,
				baseMultiplier = v.baseMultiplier and scaleMultiplier(v.baseMultiplier, scale),
				effectiveMultiplier = v.effectiveMultiplier and scaleMultiplier(v.effectiveMultiplier, scale)
			}
		end
	)

	self:applyPersistent(stats, "FR_speciesRageBonus")
end
]]