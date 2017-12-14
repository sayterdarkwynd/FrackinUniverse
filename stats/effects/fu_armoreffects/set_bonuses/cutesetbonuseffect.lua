require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_cuteset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.20}
}

armorBonus={
  {stat = "shadowResistance", amount = 0.2},
  {stat = "shadowImmunity", amount = 1}
}



function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
		return true
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
		return false
	end
end
