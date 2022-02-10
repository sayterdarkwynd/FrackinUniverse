require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_blisterset2"

weaponBonus={
	{stat = "critChance", amount = 4},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "mentalProtection", amount = 0.2},
	{stat = "poisonStatusImmunity", amount = 1.0},
	{stat = "protoImmunity", amount = 1.0},
	{stat = "pusImmunity", amount = 1.0},
	{stat = "liquidnitrogenImmunity", amount = 1.0}
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
		status.removeEphemeralEffect( "glowyellow" )
	else
		status.addEphemeralEffect( "glowyellow" )
	end
end

function checkWeapons()
	local weapons=weaponCheck({"blister","bioweapon"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

