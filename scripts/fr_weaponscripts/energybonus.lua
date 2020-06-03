-- Possible args:
--     args.energyReq = 0.xx   -- Activate bonus if above xx%
--     args.inverse            -- If true, activate if below xx%
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers
--     args.controlParameters  -- Control parameters
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, ...)
    if not args.inverse and status.resource("energy") / status.stat("maxEnergy") >= (args.energyReq or 0.25) then
        self:applyStats(args, args.name or "FR_energyBonus", ...)
    elseif args.inverse and status.resource("energy") / status.stat("maxEnergy") <= (args.energyReq or 0.25) then
        self:applyStats(args, args.name or "FR_energyBonus", ...)
    else
        self:clearPersistent(args.name or "FR_energyBonus")
    end
end
