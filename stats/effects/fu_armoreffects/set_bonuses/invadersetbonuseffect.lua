setName="fu_invaderset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", baseMultiplier = 1.20}
}

armorEffect={
	{stat = "protoImmunity", amount = 1.0},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.75}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end


function checkWeapons()
	local weapons=weaponCheck({"magnorb", "magnorbs", "energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end