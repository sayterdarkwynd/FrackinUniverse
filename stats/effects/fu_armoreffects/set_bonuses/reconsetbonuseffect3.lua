setName="fu_reconset3"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.22},
	{stat = "critChance", amount = 3}
}

armorBonus={
		{stat = "ffextremeradiationImmunity", amount = 1.0},
		{stat = "radiationburnImmunity", amount = 1.0}
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

	mcontroller.controlModifiers({
			speedModifier = 1.15
		})
end

function checkWeapons()
	local weapons=weaponCheck({"rifle","sniperrifle"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end