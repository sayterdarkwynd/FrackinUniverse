require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_battlebornset"

armorBonus2={
	{stat = "maxHealth", effectiveMultiplier = 1.24},
	{stat = "powerMultiplier", effectiveMultiplier = 1.12},
	{stat = "physicalResistance", amount = 0.1},
	{stat = "poisonResistance", amount = 0.1}
}

armorBonus={
	{stat = "broadswordMastery", amount = 0.15},
	{stat = "sulphuricImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})

	checkWorld()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWorld()
	end
end

function checkWorld()
	if checkBiome({"metallicmoon", "urbanwasteland", "scorched"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end