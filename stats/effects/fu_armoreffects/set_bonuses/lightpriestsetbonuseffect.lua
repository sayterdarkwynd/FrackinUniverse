setName="fu_lightpriestset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.10}
}

armorBonus={ }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
		status.modifyResourcePercentage("health", 0.004 * dt)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"staff","wand"})
	if weapons["both"] or weapons["twoHanded"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end