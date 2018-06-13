require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "maxHealth", baseMultiplier = 1.25},
	{stat = "protection", amount = 5},
	{stat = "breathProtection", amount = 1.0},
	{stat = "poisonResistance", amount = 0.22},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.15}
}

armorEffect={
	{stat = "breathProtection", amount = 1.0},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.15}
}

setName="fu_sirenset"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
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
	if (world.type() == "ocean") or (world.type() == "tidewater") then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end