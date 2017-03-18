require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 9}
}


armorBonus={
	{stat = "protoImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1}
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