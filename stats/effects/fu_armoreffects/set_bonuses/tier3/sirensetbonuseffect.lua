require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_sirenset"

armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.15},
	{stat = "breathProtection", amount = 1}
}
environmentBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "protection", effectiveMultiplier = 1.05}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.environmentBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)

	checkWorld()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWorld()
	end
end

function checkWorld()
	if checkBiome({"ocean", "tidewater"}) then
		effect.setStatModifierGroup(effectHandlerList.environmentBonusHandle,environmentBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.environmentBonusHandle,{})
	end
end