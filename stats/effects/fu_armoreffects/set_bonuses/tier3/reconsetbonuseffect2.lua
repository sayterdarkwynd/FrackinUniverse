require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_reconset2"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critChance", amount = 2}
}

armorBonus={
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = 1.1})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle", "sniperrifle"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end