require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 15},
	{stat = "powerMultiplier", amount = 0.15},
	{stat = "shipMass", baseMultiplier = 0.70}
}

armorBonus={
		{stat = "energyRegenPercentageRate", baseMultiplier = 1.25},
		{stat = "energyRegenBlockTime", baseMultiplier = 0.85}
}

setName="fu_lunariset"


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
	local weapons=weaponCheck({"lunari"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end