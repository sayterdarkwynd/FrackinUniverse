-- Possible args:
--     args.healthReq = 0.xx   -- Activate bonus if above xx%
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers
--     args.controlParameters  -- Control parameters
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, ...)
    if status.resourcePercentage("health") >= (args.healthReq or 0.75) then
        self:applyStats(args, args.name or "FR_healthyBonus", ...)
    else
        self:clearPersistent(args.name or "FR_healthyBonus")
    end
end
