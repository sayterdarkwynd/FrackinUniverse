setName="fu_reconset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus={
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
		speedModifier = 1.05
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