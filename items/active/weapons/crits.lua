require "/scripts/util.lua"
require "/items/active/tagCaching.lua"
Crits = {}

function Crits:setCritDamage(damage)
	if not Crits.initialLoadDone then
		Crits.initialLoad()
	end
	if (Crits.canCrit or Crits.canStun) then
		local critChance = Crits.weaponCritChance + status.stat("critChance")  -- Integer % chance to activate crit
		local critBonus = Crits.weaponCritBonus + status.stat("critBonus")     --  it's just critDamage (below). should mostly phase out except for on weapon configs.
		local critDamage = status.stat("critDamage")  -- % increase to crit damage multiplier (0.10 == +10% or 110% total additional damage)
		local stunChance = status.stat("stunChance") + Crits.weaponStunChance

		local crit = Crits.canCrit and (math.random(100)<=critChance) -- Chance out of 100
		local stun = Crits.canStun and (math.random(100)<=stunChance)

		damage = crit and (damage * (1.5 + critDamage + (critBonus/100.0))) or damage -- Inherent 50% damage boost further increased by critBonus

		if stun then
			local projectile
			local paramsStun
			local statusEffectsStun

			if(crit) then
				projectile=Crits.critStunProjectile
				paramsStun=Crits.critStunProjectileParams
				statusEffectsStun=Crits.critStunStatusEffects
			else
				projectile=Crits.stunProjectile
				paramsStun=Crits.stunProjectileParams
				statusEffectsStun=Crits.stunStatusEffects
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

function itemHasTag(item,tag)
	local tagData=tagCaching.fetchTags(item,true)
	for _,v in pairs(tagData) do
		if string.lower(v)==string.lower(tag) then
			return true
		end
	end
	return false
end

function Crits.initialLoad()
	local heldItem = world.entityHandItemDescriptor(activeItem.ownerEntityId(), activeItem.hand())
	if heldItem then
		local specialCritConfig=root.assetJson("/items/active/weapons/Crits.config")
		heldItem=root.itemConfig(heldItem)

		local buffer=true
		for _,tag in pairs(specialCritConfig.critExclusions) do
			if(itemHasTag(heldItem,tag)) then
				buffer=false
				break
			end
		end
		Crits.canCrit=buffer

		buffer=true
		for _,tag in pairs(specialCritConfig.stunExclusions) do
			if(itemHasTag(heldItem,tag)) then
				buffer=false
				break
			end
		end
		Crits.canStun=buffer

		buffer=0
		for tag,value in pairs(specialCritConfig.baseStunChanceModifiers) do
			if itemHasTag(item,tag) then
				buffer = math.max(buffer,value)
			end
		end
		local baseStunMod=buffer

		buffer=0
		for tag,value in pairs(specialCritConfig.baseCritChanceModifiers) do
			if itemHasTag(item,tag) then
				buffer = math.max(buffer,value)
			end
		end
		local baseCritMod=buffer

		buffer=nil
		for tag,value in pairs(specialCritConfig.critStunProjectileParams) do
			if itemHasTag(item,tag) then
				buffer=copy(value)
			end
		end
		local baseCritStunParams=buffer

		buffer=nil
		for tag,value in pairs(specialCritConfig.stunProjectileParams) do
			if itemHasTag(item,tag) then
				buffer=copy(value)
			end
		end
		local baseStunParams=buffer

		buffer=nil
		for tag,value in pairs(specialCritConfig.stunStatusEffects) do
			if itemHasTag(item,tag) then
				buffer=copy(value)
			end
		end
		local stunStatusEffects=buffer

		buffer=nil
		for tag,value in pairs(specialCritConfig.critStunStatusEffects) do
			if itemHasTag(item,tag) then
				buffer=copy(value)
			end
		end
		local critStunStatusEffects=buffer

		Crits.critStunProjectile=config.getParameter("critStunProjectile") or specialCritConfig.defaultProjectileCrit
		Crits.critStunProjectileParams=config.getParameter("critStunProjectileParams") or baseCritStunParams or specialCritConfig.defaultParamsCrit
		Crits.critStunStatusEffects=config.getParameter("critStunStatusEffects") or critStunStatusEffects

		Crits.stunProjectile=config.getParameter("stunProjectile") or specialCritConfig.defaultProjectile
		Crits.stunProjectileParams=config.getParameter("stunProjectileParams") or baseStunParams or specialCritConfig.defaultParams
		Crits.stunStatusEffects=config.getParameter("stunStatusEffects") or stunStatusEffects

		Crits.weaponCritChance=config.getParameter("critChance", 1)+baseCritMod
		Crits.weaponStunChance=config.getParameter("stunChance",0)+baseStunMod
		Crits.weaponCritBonus=config.getParameter("critBonus", 0)

		Crits.initialLoadDone=true
	end
end
