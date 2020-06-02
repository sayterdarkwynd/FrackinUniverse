--[[
    Simple HP regeneration effect.
	Restores the given % of HP every second this is active.
    Arguments:

	"args" : {
		"healingRate" = 0.015
	}
]]

function FRHelper:call(args, main, dt, ...)
	status.modifyResourcePercentage("health", args.healingRate * dt)
end
