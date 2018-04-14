require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_samuraiset"


weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "critChance", amount = 2}
}

weaponBonus2={
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "critChance", amount = 1},
	{stat = "protection", baseMultiplier = 1.1}
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
	local weaponKatana=weaponCheck({"katana"})
	local weaponDagger=weaponCheck({"dagger"})

	if weaponKatana["either"] and weaponDagger["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)
	elseif (weaponKatana["either"]) and not weaponKatana["both"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)				
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end