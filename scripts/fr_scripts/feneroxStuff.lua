function FRHelper:call(args, main, dt, ...)
    local nighttime = world.timeOfDay() > 0.5
    local underground = world.underground(mcontroller.position())

    local foodValue
    if status.isResource("food") then
        foodValue = status.resourcePercentage("food")
    else
        foodValue = args.foodDefault
    end

    if nighttime or underground and (foodValue >= args.foodThreshold) then
		--special handling for NPCs, to prevent immortality
		if not (world.isNpc(entity.id()) and status.resource("health") < 1) then
			status.modifyResourcePercentage("health", args.healingRate * dt)
		else
			status.setResource("health",0)
		end

        self:applyStats(args, args.name or "FR_feneroxNightBonus", main, dt, ...)
    else
        self:clearPersistent(args.name or "FR_feneroxNightBonus")
    end
end
