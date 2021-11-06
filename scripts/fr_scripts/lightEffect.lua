-- Possible args:
--     args.lightLevel         -- Effect applied at >= light level (integer %)
--     args.dark               -- Effect applied at <= light level when true
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers
--     args.controlParameters  -- Control parameters
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, ...)
    local position = mcontroller.position()
    position[1] = math.floor(position[1])
    position[2] = math.floor(position[2])
    local lightLevel = math.floor(world.lightLevel(position)*100)

    if not args.dark and lightLevel >= args.lightLevel then
        self:applyStats(args, args.name or "FR_lightEffect", ...)
    elseif lightLevel <= args.lightLevel then
        self:applyStats(args, args.name or "FR_lightEffect", ...)
    else
        self:clearPersistent(args.name or "FR_lightEffect")
    end
end
