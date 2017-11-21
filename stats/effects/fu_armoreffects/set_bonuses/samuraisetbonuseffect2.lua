require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_samuraiset2"


weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "critChance", amount = 3}
}

weaponBonus2={
        {stat = "powerMultiplier", baseMultiplier = 1.15},
        {stat = "critChance", amount = 1},
	{stat = "protection", baseMultiplier = 1.14}
}

armorBonus={
	{stat = "physicalResistance", amount = 0.05}
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
local weaponSingle=weaponCheck({"katana"})
local weaponDual=weaponCheck({"katana","dagger"})

	if weaponSingle["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	elseif weaponDual["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)				
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end