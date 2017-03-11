require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "maxHealth", amount = 5},
	{stat = "powerMultiplier", amount = 0.05},
	{stat = "physicalResistance", amount = 0.05}
}

armorEffect={
	{stat = "maxHealth", amount = 5},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.925}
}

setName="fu_boneset"

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
	end
end

function checkArmor()
	if (world.type() == "garden") or (world.type() == "forest") then
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(
		armorBonusHandle,{})
	end
end