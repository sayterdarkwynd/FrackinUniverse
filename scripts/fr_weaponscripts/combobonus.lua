-- Possible args:
--     args.comboMult          -- Multiplier per combo step (x1 = x3 for a step 3 combo, defaults to 1)
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers #NOT SUPPORTED YET
--     args.controlParameters  -- Control parameters #NOT SUPPORTED YET
--     args.scripts            -- Activate other scripts?! #NOT HERE

function FRHelper:call(args, main, ...)
    if not main.comboStep then return end  -- Don't run in the wrong place!
    local multiplier = main.comboStep * (args.comboMult or 1)
    local newargs = {stats={}}
    for _,x in ipairs(args.stats) do
        table.insert(newargs.stats, {})
        newargs.stats[_].stat = x.stat
        if x.amount then  -- multiply amounts
            newargs.stats[_].amount = x.amount * multiplier
        end
        if x.baseMultiplier then  -- subtract 1, multiply, then re-add the 1, but don't go below 0!
            newargs.stats[_].baseMultiplier = math.max((x.baseMultiplier - 1 * multiplier) + 1, 0.0000001)
        end
    end
    self:applyStats(newargs, args.name or "FR_comboBonus", main, ...)
end
