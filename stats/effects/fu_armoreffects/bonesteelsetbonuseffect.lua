setName="fu_bonesteelset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus2={
{stat = "maxHealth", baseMultiplier = 1.10},
{stat = "maxEnergy", baseMultiplier = 1.05},
{stat = "physicalResistance", amount = 0.20},
{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

armorBonus={
	{stat = "physicalResistance", amount = 0.15},
{stat = "maxHealth", baseMultiplier = 1.05},
{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
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
	if (world.type() == "garden") or (world.type() == "forest") then
		effect.setStatModifierGroup(
	armorBonusHandle,armorBonus2)
	else
		effect.setStatModifierGroup(
	armorBonusHandle,armorBonus)
	end
	
	checkWeapons()
end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"broadsword","shortsword"})
if weapons["either"] then
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end