setName="fu_decimatorset"

weaponBonus={
	{stat = "critChance", amount = 3},
	{stat = "critBonus", baseMultiplier = 1.15}
}

armorBonus={
	{stat = "protoImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1}
}

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
	end
end

function checkWeapons()
	local weapons=weaponCheck({"shotgun","grenadelauncher"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end