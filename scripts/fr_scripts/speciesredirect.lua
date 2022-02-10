--[[
    Redirects a species to another species' bonuses
	"args" : {
		"species":<destinationSpecies>
	}
]]

function FRHelper:call(args, main, dt, ...)
	if args.species then
		--sb.logInfo("redirecting species to %s",args.species)
		status.setStatusProperty("fr_race", args.species)
	end
end
