require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_spacefarerset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 2.0}
}

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "protoImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "maxBreath", amount = 1400},
	{stat = "defensetechBonus", amount = 0.5}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
end

function checkWeapons()
	local mininglasers=weaponCheck({"mininglaser"})
	local weapons=weaponCheck({"weapon"})
	if (mininglasers["primary"] and mininglasers["alt"]) or (mininglasers["twoHanded"] and mininglasers["either"]) or ((not weapons["either"]) and mininglasers["either"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	elseif mininglasers["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,0.25))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end