require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.15}
}

armorBonus={
        {stat = "biomecoldImmunity", amount = 1},
        {stat = "biomeheatImmunity", amount = 1},
        {stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
        {stat = "breathProtection", amount = 1}	
}

setName="fu_sunwalkerset"

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
	local weapons=weaponCheck({"plasma"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end