require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_nautilusset"

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "maxBreath", amount = 700},
	{stat = "breathRegeneration", baseMultiplier = 1.5}
}

armorBonus2={
	{stat = "critChance", amount = 3},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
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
	if checkBiome({"ocean", "sulphuricocean", "aethersea", "tidewater", "nitrogensea", "strangesea"}) then
		mcontroller.controlModifiers({speedModifier = 1.05})
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end