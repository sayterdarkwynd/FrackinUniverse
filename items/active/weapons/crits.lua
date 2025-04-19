require "/scripts/util.lua"
Crits = {}
--no. root doesnt exist at this point.
--Crits.specialCritConfig=root.assetJson("/items/active/weapons/Crits.specialCritConfig")

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

	Pass R1 	2.0105	Pass R2 	0.9941
--translated, this output means that when attempting to get a roll out of 100, the average roll will be these.
--in other words, math.random(100)>=99 means 2% chance, not 1%.
--changing the comparison from >= to > thus results in reducing the 'success' chance over an average of 1 million samples by ~1.0.
]]

function Crits:setCritDamage(damage)
	local owner=activeItem.ownerEntityId()

	if not Crits.specialCritConfig then
		Crits.specialCritConfig=root.assetJson("/items/active/weapons/Crits.config")
	end

	local heldItem = world.entityHandItemDescriptor(owner, activeItem.hand())
	local canCrit=Crits.canCrit(heldItem)
	local canStun=Crits.canStun(heldItem)

	if (canCrit or canStun) then
		local critChance = config.getParameter("critChance", 1) + status.stat("critChance") + Crits.getBaseCritMod(item)  -- Integer % chance to activate crit
		local critBonus = config.getParameter("critBonus", 0) + status.stat("critBonus")     --  it's just critDamage (below). should mostly phase out except for on weapon configs.
		local critDamage = status.stat("critDamage")  -- % increase to crit damage multiplier (0.10 == +10% or 110% total additional damage)
		local stunChance = status.stat("stunChance") + config.getParameter("stunChance",0) + Crits.getBaseStunMod(item)

		local crit = canCrit and (math.random(100)<=critChance) or false -- Chance out of 100
		local stun = canStun and (math.random(100)<=stunChance) or false

		damage = crit and (damage * (1.5 + critDamage + (critBonus/100.0))) or damage -- Inherent 50% damage boost further increased by critBonus

		-- local race = world.sendEntityMessage(activeItem.ownerEntityId(), "FR_getSpecies")
		-- if race:succeeded then race=race:result() else race=nil end

		-- if crit then
			-- if race == "glitch" and (itemHasTag(heldItem("mace")) or itemHasTag(heldItem, "axe") or itemHasTag(heldItem, "greataxe")) then
				-- damage = damage + math.random(10) + 2  -- 1d10 + 2 bonus damage
			-- end
		-- end
		--sb.logInfo("crits.lua 1: %s",{itemname=config.getParameter("shortdescription"),canCrit=canCrit,canStun=canStun,critChance=critChance,critDamage=critDamage,stunChance=stunChance,crit=crit,stun=stun})

		if stun then
			local projectile
			local paramsStun
			local statusEffectsStun

			if(crit) then
				projectile=config.getParameter("critStunProjectile") or Crits.specialCritConfig.defaultProjectileCrit
				paramsStun=config.getParameter("critStunProjectileParams") or Crits.getBaseParams(item,crit) or copy(Crits.specialCritConfig.defaultParamsCrit)
				statusEffectsStun=config.getParameter("critStunStatusEffects")
			else
				projectile=config.getParameter("stunProjectile") or Crits.specialCritConfig.defaultProjectile
				paramsStun=config.getParameter("stunProjectileParams") or Crits.getBaseParams(item,crit) or copy(Crits.specialCritConfig.defaultParams)
				statusEffectsStun=config.getParameter("stunStatusEffects")
			end
			if statusEffectsStun then
				paramsStun.statusEffects=statusEffectsStun
			end
			world.spawnProjectile(projectile,mcontroller.position(),activeItem.ownerEntityId(),Crits.aimVectorSpecial(self),false,paramsStun)
		end
	end

	return damage
end

function Crits:aimVectorSpecial()
    local aimVector = vec2.rotate({1, 0}, self.aimAngle)
	aimVector[1] = aimVector[1] * self.aimDirection
	return aimVector
end

function fetchTags(iConf)
	if not Crits.tagCache then
		local tags={}
		for k,v in pairs(iConf.config or {}) do
			if string.lower(k)=="itemtags" then
				tags=util.mergeTable(tags,copy(v))
			end
		end
		for k,v in pairs(iConf.parameters or {}) do
			if string.lower(k)=="itemtags" then
				tags=util.mergeTable(tags,copy(v))
			end
		end
		Crits.tagCache=tags
	end
	return Crits.tagCache
end

function itemHasTag(item,tag)
	local tagData=fetchTags(item)
	for _,v in pairs(tagData) do
		if string.lower(v)==string.lower(tag) then
			return true
		end
	end
	return false
end

function Crits.canCrit(item)
	if item then
		for _,tag in pairs(Crits.specialCritConfig.critExclusions) do
			if(itemHasTag(item,tag)) then
				return false
			end
		end
		return true
	end
	return false
end

function Crits.canStun(item)
	if item then
		for _,tag in pairs(Crits.specialCritConfig.stunExclusions) do
			if(itemHasTag(item,tag)) then
				return false
			end
		end
		return true
	end
	return false
end

function Crits.getBaseStunMod(item)
	local base=0
	if item then
		for tag,value in pairs(Crits.specialCritConfig.baseStunChanceModifiers) do
			if itemHasTag(item,tag) then
				base = math.max(base,value)
			end
		end
	end
	return base
end

function Crits.getBaseCritMod(item)
	local base=0
	if item then
		for tag,value in pairs(Crits.specialCritConfig.baseCritChanceModifiers) do
			if itemHasTag(item,tag) then
				base = math.max(base,value)
			end
		end
	end
	return base
end

function Crits.getBaseParams(item,crit)
	if item then
		for tag,value in pairs((crit and (Crits.specialCritConfig.critStunProjectileParams)) or (Crits.specialCritConfig.stunProjectileParams)) do
			if itemHasTag(item,tag) then
				return copy(value)
			end
		end
	end
end
