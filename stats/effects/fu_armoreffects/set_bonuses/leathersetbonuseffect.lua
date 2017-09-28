setName="fu_leatherset"

weaponBonus={
	{stat = "critChance", amount = 5},
        {stat = "powerMultiplier", amount = 0.05}
}

armorBonus={
	{stat = "grit", amount = 0.05},
        {stat = "maxEnergy", amount = 5}
}

armorEffect={
	{stat = "critChance", amount = 2}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	weaponBonusHandle=effect.addStatModifierGroup({})

	armorBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
        checkArmor()
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
else
	
	checkWeapons()
	checkArmor()
end

mcontroller.controlModifiers({
	speedModifier = 1.05
})
end

function checkArmor()
	if (world.type() == "garden") or (world.type() == "forest") then
	  effect.setStatModifierGroup(
	  armorBonusHandle,armorBonus)
	else
	  effect.setStatModifierGroup(
	  armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"bow"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end