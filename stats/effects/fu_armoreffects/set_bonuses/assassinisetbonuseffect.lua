require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 2}
}


armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1}
}


setName="fu_assassiniset"


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
local weaponSword=weaponCheck({"pistol", "machinepistol"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end