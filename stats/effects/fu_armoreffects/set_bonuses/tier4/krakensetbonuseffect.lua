require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_krakenset"

armorBonus2={
	{stat = "critChance", amount = 4},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	checkBiomeBonus()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("swimboost2")
		effect.expire()
	else
		status.addEphemeralEffect("swimboost2")
		checkBiomeBonus()
	end

end

function checkBiomeBonus()
	if checkBiome({"ocean","sulphuricocean","aethersea","nitrogensea","strangesea","tidewater"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
		applyFilteredModifiers({speedModifier = 1.05})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end
