setName="fu_samuraiset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15},
	{stat = "critChance", amount = 5}
}

armorBonus={
	{stat = "physicalResistance", amount = 0.05}
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

function 
	checkWeapons()
	local weapons=weaponCheck({"shortsword","broadsword"})
if weapons["either"] then
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end