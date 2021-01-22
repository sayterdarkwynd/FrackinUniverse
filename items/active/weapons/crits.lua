Crits = {}

function Crits:setCritDamage(damage)
    local critChance = config.getParameter("critChance", 1) + status.stat("critChance")  -- Integer % chance to activate crit
    local critBonus = config.getParameter("critBonus", 0) + status.stat("critBonus")     --  % damage bonus to critical hits
    local critDamage = status.stat("critDamage")  -- % increase to crit damage multiplier (0.10 == +10% or 110% total additional damage)
	--status.stat ONLY accepts ONE argument. and returns 0.0 if it is not found
	local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
    -- Magnorbs get an inherent +1% crit chance
    if heldItem and root.itemHasTag(heldItem, "magnorb") then
        critChance = critChance + 1
    end

	local crit = math.random(100) <= critChance -- Chance out of 100

    -- Crit damage bonus is 50% + critDamage%
	damage = crit and (damage * (1.5 + critDamage) + critBonus) or damage -- Inherent 50% damage boost further increased by critBonus

	if crit then
        if heldItem then
            -- exclude mining lasers
            if not root.itemHasTag(heldItem, "mininggun") or root.itemHasTag(heldItem, "bugnet") then

				-- Glitch ability
				local race = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
                if race:succeeded() and race:result() == "glitch" and (root.itemHasTag(heldItem, "mace") or root.itemHasTag(heldItem, "axe") or root.itemHasTag(heldItem, "greataxe")) then
                    damage = damage + math.random(10) + 2  -- 1d10 + 2 bonus damage
                end

                -- *****************************************************************
                --	weapon specific crit abilities!
                -- *****************************************************************
                local stunChance = math.random(100) + status.stat("stunChance") + config.getParameter("stunChance",0)
                local daggerChance = math.random(100) + status.stat("daggerChance") + config.getParameter("daggerChance",0)

                if stunChance >= 95 and root.itemHasTag(heldItem, "dagger") then
                    params = { speed=14, power = 1, damageKind = "default"}
                    world.spawnProjectile("daggerCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),true,params)
                end
                if stunChance >= 99 and root.itemHasTag(heldItem, "spear") then
                    params = { speed=55, power = 1, damageKind = "default"}
                    world.spawnProjectile("spearCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunChance >= 99 and root.itemHasTag(heldItem, "shortspear") then
                    params = { speed=22, power = 1, damageKind = "default"}
                    world.spawnProjectile("spearCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunChance >= 99 and root.itemHasTag(heldItem, "rapier") or root.itemHasTag(heldItem, "shortsword") then
                    params = { speed=30, power = 1, damageKind = "default"}
                    world.spawnProjectile("rapierCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunChance >= 99 and (root.itemHasTag(heldItem, "hammer") or root.itemHasTag(heldItem, "greataxe") or root.itemHasTag(heldItem, "quarterstaff") or root.itemHasTag(heldItem, "mace")) then -- Stun!!!!
                    params = { speed=35, power = 1, damageKind = "default"}
                    world.spawnProjectile("shieldBashStunProjectile",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
            end
        end
	end

	return damage
end

function Crits:aimVectorSpecial()
    local aimVector = vec2.rotate({1, 0}, self.aimAngle)
	aimVector[1] = aimVector[1] * self.aimDirection
	return aimVector
end
