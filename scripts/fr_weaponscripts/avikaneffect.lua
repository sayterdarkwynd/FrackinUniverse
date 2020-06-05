-- Possible args:
--     args.mod                -- Amount to divide by
--     args.resource           -- Resource to use (health by default)
--     args.comboMult          -- Combo multiplier (0 = ignore combos)
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats (base value, everything else added on top)
--     args.controlModifiers   -- Control modifiers   #NOT YET SUPPORTED
--     args.controlParameters  -- Control parameters  #NOT YET SUPPORTED
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, main, ...)
    local multiplier = (main.comboStep or 0) * (args.multiplier or 1)
    multiplier = multiplier == 0 and 1 or multiplier  -- set to 1 if 0
    local bonus = status.resource(args.resource or "health") / (args.mod or 30)
    local newargs = {stats={}}
    for _,s in ipairs(args.stats or {}) do
        table.insert(newargs.stats, {stat=s.stat})
        if s.amount then  -- Normal calculation for amounts
            newargs.stats[_].amount = s.amount + (multiplier * bonus)
        end
        if s.baseMultiplier then  -- Convert to percent for baseMultipliers
            newargs.stats[_].baseMultiplier = s.baseMultiplier + (multiplier * bonus * 0.01)
        end
    end
    self:applyStats(newargs, args.name or "FR_healthyBonus", main, ...)
end
