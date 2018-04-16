require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_pyreiteset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1}
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
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"pyreite"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end