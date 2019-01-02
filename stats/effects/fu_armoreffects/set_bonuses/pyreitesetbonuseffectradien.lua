require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_pyreitesetradien"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25},
	{stat = "xiBonus", baseMultiplier = 1.30}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(
		effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"radien"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end