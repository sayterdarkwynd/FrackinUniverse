--[[
Arg structure:

No args for this one. Not yet, anyway.

ONLY run in bows! Or something else that has firePosition and aimVector methods
]]

function FRHelper:call(args, main, dt, ...)
    local energyValue = status.resource("energy") or 100

    -- 10% chance of random projectile
    if math.random(10) == 1	then
        local attackType = math.random(6)
        if (attackType) == 1 and (energyValue) >= 100 then
            params = { power = energyValue/10 , damageKind = "poison", speed = 45, timeToLive = 3 }
            projectileId = world.spawnProjectile("purplearrow",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        elseif (attackType) == 2 and (energyValue) >= 100 then
            params = { power = energyValue/12 , damageKind = "fire", speed = 60, timeToLive = 3 }
            projectileId = world.spawnProjectile("chargedpurplearrow",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        elseif (attackType) == 3 and (energyValue) >= 100 then
            params = { power = energyValue/12 , damageKind = "ice", speed = 30, timeToLive = 1 }
            projectileId = world.spawnProjectile("magentaglobelamia",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        elseif (attackType) == 4 and (energyValue) >= 100 then
            params = { power = energyValue/12 , damageKind = "shadow", speed = 50, timeToLive = 1 }
            projectileId = world.spawnProjectile("poisonplasma",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        elseif (attackType) == 5 and (energyValue) >= 100 then
            params = { power = energyValue/12 , damageKind = "electric", speed = 50, timeToLive = 1 }
            projectileId = world.spawnProjectile("ngravitybolt",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        elseif (attackType) == 6 and (energyValue) >= 100 then
            params = { power = energyValue/12 , damageKind = "radioactive", speed = 30, timeToLive = 1 }
            projectileId = world.spawnProjectile("orangeglobelamia",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        else
            params = { power = energyValue/12 , damageKind = "cosmic", speed = energyValue/3, timeToLive = 3 }
            projectileId = world.spawnProjectile("purplearrow",main:firePosition(),activeItem.ownerEntityId(),main:aimVector(),false,params)
        end
    end

    -- Energy and luck based crit chance bonus
    local randValueCritBonus = math.random(4)
    local critValueLamia = ( randValueCritBonus + math.ceil(energyValue/40) )
    if energyValue >= (status.stat("maxEnergy")*0.5) then	-- with high Energy reserve, lamia get increased Bow crit chance
        status.modifyResource("energy", (energyValue * -0.01) )	-- consume energy
        self:applyStats({stats={
            {stat = "critChance", amount = critValueLamia},
            {stat = "powerMultiplier", baseMultiplier = 1 + (critValueLamia/100) * 2}
        }}, "lamiabowbonus", main, dt, ...)
    end
end
