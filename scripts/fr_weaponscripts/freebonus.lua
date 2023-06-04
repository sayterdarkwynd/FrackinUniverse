-- This is used to apply stat buffs on weapon scripts, rather than specific types

-- Possible args:
--     args.healthReq = 0.xx   -- Activate bonus if above xx%
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers
--     args.controlParameters  -- Control parameters
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, ...)
    self:applyStats(args, args.name or "FR_freeBonus", ...)
end
