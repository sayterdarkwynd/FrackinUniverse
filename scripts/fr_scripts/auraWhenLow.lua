

function FRHelper:call(args, main, dt)
    self.auraReload = (self.auraReload or args.auraReload) - dt
    local res
    if not status.isResource(args.resource) then
        res = args.resourceDefault
    else
        res = status.resourcePercentage(args.resource)
    end
    if self.auraReload <= 0 and res < args.threshold then
        world.spawnProjectile(args.projType, mcontroller.position(), entity.id(), args.projVelocity or {0, 0}, args.track, args.projParameters)
        self.auraReload = args.auraReload
    end
end
