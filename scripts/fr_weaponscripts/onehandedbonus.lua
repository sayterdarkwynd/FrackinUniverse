-- Possible args:
--     args.name               -- Overrides the persistent effect name
--     args.stats              -- Stats
--     args.controlModifiers   -- Control modifiers
--     args.controlParameters  -- Control parameters
--     args.scripts            -- Activate other scripts?!

function FRHelper:call(args, ...)
    if not activeItem then return end   -- Don't run if running in the wrong place!
    local thisItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
    if not root.itemConfig(thisItem).config.twoHanded then
        self:applyStats(args, args.name or "FR_oneHandedEffect", ...)
    end
end
