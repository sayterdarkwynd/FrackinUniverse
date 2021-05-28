require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_copperarmorsetnew"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.4}
}

weaponBonus2={
	{stat = "maxEnergy", effectiveMultiplier = 1.2}
}

armorBonus={
	{stat = "fumudslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonus2Handle=effect.addStatModifierGroup({})

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
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,weaponBonus2)
	elseif mininglasers["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,0.25))
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,{})
	end
end