setName="fu_reconset2"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15},
	{stat = "critChance", amount = 2}
}

armorBonus={
		{stat = "biomeradiationImmunity", amount = 1.0},
		{stat = "radiationburnImmunity", amount = 1.0}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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

	mcontroller.controlModifiers({
			speedModifier = 1.10
		})
end

function 
	checkWeapons()
	local weapons=weaponCheck({"rifle","sniperrifle"})
if weapons["either"] then
	effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
end
end