require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_geologistset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.5} }

armorBonus={
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "researchBonus", amount = 2}
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

		checkWeapons()
	end
end

function checkWeapons()
	local mininglasers=weaponCheck({"mininglaser"})
	local notweapons=not weaponCheck({"weapon"})["either"]
	if (mininglasers["primary"] and mininglasers["alt"]) or (mininglasers["twoHanded"] and mininglasers["either"]) or (notweapons and mininglasers["either"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	elseif mininglasers["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,0.25))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end