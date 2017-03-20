require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "maxHealth", baseMultiplier = 1.25},
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "physicalResistance", amount = 1.25}
}

armorEffect={
	{stat = "sulphuricImmunity", amount = 5},
	{stat = "poisonStatusImmunity", baseMultiplier = 1}
}

setName="fu_corruptset"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
		randValue = math.random(100)	
		if (randValue < 5) and (lightLevel < 26) then  -- spawn a projectile
		  params = { power = 5, damageKind = "shadow" }			
		  projectileId = world.spawnProjectile("scouteye",self:firePosition(),activeItem.ownerEntityId(),self:aimVector(),false,params)
		end			
	end
end

function checkArmor()
	if (world.type() == "lightless") or (world.type() == "penumbra") or (world.type() == "aethersea") or (world.type() == "moon_shadow") or (world.type() == "shadow") or (world.type() == "midnight") then
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(
		armorBonusHandle,{})
	end
end