require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "slimefrictionImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1}
}

setName="fu_neuromancerset"

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
	local weapons=weaponCheck({"energy"})
	
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end