--[[
    Spawns a given projectile with given parameters on a given percentage rate.
    WARNING: Only use in places with firePosition and aimVector methods!

    Args:
    projectile       -- Projectile type
    params           -- Projectile params (optional)
    chance           -- Projectile spawn chance (out of 100)
]]


function FRHelper:call(args, main, ...)
    local rand = math.random(100)
    if args.hungermod then
        args.power = (args.power or 0) + (status.resource("food") or 0)/args.hungermod
    end
    if rand <= args.chance then
        world.spawnProjectile(args.projectile, main:firePosition(), activeItem.ownerEntityId(), main:aimVector(), false, args.params or {})
    end
end
