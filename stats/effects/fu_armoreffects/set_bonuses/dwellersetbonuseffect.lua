setName="fu_dwellerset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.20}
}

armorBonus={
	{stat = "tarImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1}
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
end

function checkWeapons()
	local weapons=weaponCheck({"mininglaser"})
	if weapons["primary"] and weapons["alt"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,0.25))
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end