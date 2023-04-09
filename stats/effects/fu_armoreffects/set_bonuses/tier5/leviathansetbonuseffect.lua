require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_leviathanset"

armorBonus2={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "breathProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "pressureProtection", amount = 1}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.armorBonusHandle2=effect.addStatModifierGroup({})

	if checkBiome({"ocean","sulphuricocean","aethersea","nitrogensea","strangesea","tidewater"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle2,armorBonus2)
	end
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("swimboost3")
		effect.expire()
	else
		status.addEphemeralEffect("swimboost3")
	end
	if checkBiome({"ocean","sulphuricocean","aethersea","nitrogensea","strangesea","tidewater"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle2,armorBonus2)

		mcontroller.controlModifiers({
			speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.05
		})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle2,{})
	end
end
