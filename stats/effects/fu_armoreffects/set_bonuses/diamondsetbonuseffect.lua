require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_diamondset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={ }



function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"diamond","katana"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end

