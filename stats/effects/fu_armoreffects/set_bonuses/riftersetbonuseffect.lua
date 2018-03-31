setName="fu_rifterset"

weaponBonus={
	{stat = "critChance", amount = 3},
    {stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorEffect={
        {stat = "protoImmunity", amount = 1.0},
        {stat = "gasImmunity", amount = 1.0},
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
	local weapons=weaponCheck({"magnorb", "magnorbs", "boomerang","chakram"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end