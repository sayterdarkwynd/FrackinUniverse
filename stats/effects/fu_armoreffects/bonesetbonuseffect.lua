require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus2={
	{stat = "maxHealth", baseMultiplier = 1.10},
	{stat = "powerMultiplier", baseMultiplier = 1.05},
	{stat = "physicalResistance", amount = 0.05},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

armorBonus={
	{stat = "maxHealth", baseMultiplier = 1.05},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

setName="fu_boneset"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup({})
	if (world.type() == "garden") or (world.type() == "forest") then
		effect.setStatModifierGroup(armorHandle,armorBonus2)
	else
		effect.setStatModifierGroup(armorHandle,armorBonus)
	end
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		if (world.type() == "garden") or (world.type() == "forest") then
			effect.setStatModifierGroup(armorHandle,armorBonus2)
		else
			effect.setStatModifierGroup(armorHandle,armorBonus)
		end
	end
end