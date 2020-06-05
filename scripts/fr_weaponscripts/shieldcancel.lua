-- Possible args:
--     args.energyAmt     -- Energy % to stay above or else you lose all shield bonuses for 3 seconds

function FRHelper:call(args, ...)
    local energyValue = (status.resource("energy") or 1) / (status.stat("maxEnergy") or 1)

    if energyValue <= (args.energyAmt or 0.25) then -- if they have 25% or more energy apply the bonus. else, nope.
		status.addEphemeralEffect("raceglitchshieldcancel",3) -- 3 seconds of losing all shield buffs (if you're glitch)
	end
end
