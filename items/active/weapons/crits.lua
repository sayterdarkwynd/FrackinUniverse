Crits = {}

--[[
placing this in lua demo: 
	local passR1=0
	local passR2=0
	local sampleSize=1000000
	local comparisonValue=99

	for i=1,sampleSize do
		rand=math.random(100)--y=math.random(x): 1<=y<=100
		if(rand)>=comparisonValue then
			passR1=passR1+1
		end
		if(rand)>comparisonValue then
			passR2=passR2+1
		end
	end

	print("Pass R1 ",passR1*(100/sampleSize)," Pass R2 ",passR2*(100/sampleSize))

--results in an output like this:

	Pass R1 	2.0105	 Pass R2 	0.9941
--translated, this output means that when attempting to get a roll out of 100, the average roll will be these.
--in other words, math.random(100)>=99 means 2% chance, not 1%.
--changing the comparison from >= to > thus results in reducing the 'success' chance over an average of 1 million samples by ~1.0.
]]

function Crits:setCritDamage(damage)
    local critChance = config.getParameter("critChance", 1) + status.stat("critChance")  -- Integer % chance to activate crit
    local critBonus = config.getParameter("critBonus", 0) + status.stat("critBonus")     --  flat damage bonus to critical hits
    local critDamage = status.stat("critDamage")  -- % increase to crit damage multiplier (0.10 == +10% or 110% total additional damage)
	--status.stat ONLY accepts ONE argument. and returns 0.0 if it is not found

	--sb.logInfo("crits.lua: crit chance: %s, crit bonus %s, crit damage %s",critChance,critBonus,critDamage)
	local heldItem = world.entityHandItem(activeItem.ownerEntityId(), activeItem.hand())
    -- Magnorbs get an inherent +1% crit chance
    if heldItem and root.itemHasTag(heldItem, "magnorb") then
        critChance = critChance + 1
    end

	local crit = (math.random(100)<=critChance) -- Chance out of 100
    -- Crit damage bonus is 50% + critDamage%
	damage = crit and (damage * (1.5 + critDamage) + critBonus) or damage -- Inherent 50% damage boost further increased by critBonus

	if crit then
		--sb.logInfo("sum.critChance:%s, config.critChance:%s stat.critChance:%s",config.getParameter("critChance", 1)+status.stat("critChance"),config.getParameter("critChance", 1),status.stat("critChance"))
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
                local stunRoll = (math.random(100)) + status.stat("stunChance") + config.getParameter("stunChance",0)
                --local daggerChance = math.random(100) + status.stat("daggerChance") + config.getParameter("daggerChance",0)--unused

                if stunRoll > 99 and root.itemHasTag(heldItem, "dagger") then
                    params = { speed=14, power = 1, damageKind = "default"}
                    world.spawnProjectile("daggerCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),true,params)
                end
                if stunRoll > 99 and root.itemHasTag(heldItem, "spear") then
                    params = { speed=55, power = 1, damageKind = "default"}
                    world.spawnProjectile("spearCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunRoll > 99 and root.itemHasTag(heldItem, "shortspear") then
                    params = { speed=22, power = 1, damageKind = "default"}
                    world.spawnProjectile("spearCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunRoll > 99 and root.itemHasTag(heldItem, "rapier") or root.itemHasTag(heldItem, "shortsword") then
                    params = { speed=30, power = 1, damageKind = "default"}
                    world.spawnProjectile("rapierCrit",mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,params)
                end
                if stunRoll > 99 and (root.itemHasTag(heldItem, "fist") or root.itemHasTag(heldItem, "hammer") or root.itemHasTag(heldItem, "greataxe") or root.itemHasTag(heldItem, "quarterstaff") or root.itemHasTag(heldItem, "mace")) then -- Stun!!!!
                    --sb.logInfo("sum.stunRoll:%s, random.stunRoll:%s, stat.stunChance:%s, config.stunChance:%s",stunRoll,stunRoll-(status.stat("stunChance") + config.getParameter("stunChance",0)),status.stat("stunChance"),config.getParameter("stunChance",0))
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
