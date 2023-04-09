require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_reconset3"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.22},
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "ffextremeradiationImmunity", amount = 1.0},
	{stat = "radiationburnImmunity", amount = 1.0},
	{stat = "biomeradiationImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end

	mcontroller.controlModifiers({speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.15})
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","sniperrifle"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
