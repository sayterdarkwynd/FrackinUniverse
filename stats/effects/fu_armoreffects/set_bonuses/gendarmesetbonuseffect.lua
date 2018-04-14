require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_gendarmeset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.20}
}

armorBonus={
	{stat = "fireStatusImmunity", amount = 1.0}
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
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"rocketlauncher","grenadelauncher"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end