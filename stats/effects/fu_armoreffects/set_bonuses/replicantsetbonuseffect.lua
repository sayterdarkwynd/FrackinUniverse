require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 2}
}

weaponBonus2={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "shadowImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1}
}

setName="fu_replicantset"


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
local weaponSword=weaponCheck({"shortsword","broadsword","rapier","longsword","katana"})
local weaponShield=weaponCheck({"shortsword","broadsword","rapier","longsword","katana"})

	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	elseif weaponSword["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end