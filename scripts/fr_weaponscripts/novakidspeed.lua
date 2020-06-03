function FRHelper:call(args, main, ...)
    local lightLevel = getLight()
    local speedMod = (args.minSpeed or 1) - (lightLevel / (args.lightValue or 200))
    if (select(1, ...) and type(select(1, ...)) == "number") or main.fireType == "burst" then
        main.cooldownTimer = main.cooldownTimer * speedMod
        local x = math.max(math.min(1 - (1 - speedMod) * 0.5, args.damageCeiling or 1), args.damageFloor or 0.5)
        self:applyStats({ stats={ {stat="powerMultiplier", baseMultiplier=x} } }, "FR_novakidSpeedPenalty")
    else
        main.cooldownTimer = main.fireTime * speedMod
    end
end
