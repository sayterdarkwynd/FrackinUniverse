require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_chaosset"

weaponBonus1={
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "daggerMastery", amount = 0.15}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		setRegen(0.0)
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = 1.1})

		checkWeapons()
		setRegen(0.005)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger", "knife", "whip", "boomerang", "chakram"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end