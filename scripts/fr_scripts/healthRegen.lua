--[[
    Simple HP regeneration effect.
	Restores the given % of HP every second this is active.
    Arguments:

	"args" : {
		"healingRate" = 0.015
	}
]]

function FRHelper:call(args, main, dt, ...)
	--special handling for NPCs, to prevent immortality
	if not (world.isNpc(entity.id()) and status.resource("health") < 1) then
		status.modifyResourcePercentage("health", args.healingRate * dt)
	else
		status.setResource("health",0)
	end
end
