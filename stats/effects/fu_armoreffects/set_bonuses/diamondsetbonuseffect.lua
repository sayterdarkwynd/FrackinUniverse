require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_diamondset"


weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25},
	{stat = "critChance", amount = 5}
}

armorBonus={}


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

	if weaponSingle["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)				
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end