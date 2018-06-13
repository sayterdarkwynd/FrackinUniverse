require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_junkerset"

weaponBonus={ { stat = "powerMultiplier" , effectiveMultiplier = 1.25} }

armorBonus={
	{stat = "gasImmunity", amount = 1.0},
	{stat = "sulphuricImmunity", amount = 1.0},
	{stat = "maxBreath", amount = 800},
	{stat = "energyRegenBlockTime", baseMultiplier = 0.75},
	{stat = "energyRegenPercentageRate", amount = 0.15}
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
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	end
end


function 
	checkWeapons()
	local weapons=weaponCheck({ "grenadelauncher" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end