require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_researchset"

weaponBonus={ { stat = "powerMultiplier" , effectiveMultiplier = 1.25} }

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "breathProtection", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "radioactiveResistance", amount = 0.15}
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
	local weapons=weaponCheck({ "magnorb" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end