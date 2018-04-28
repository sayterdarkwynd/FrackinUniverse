require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_cellularset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.20}
}

armorBonus={
	{stat = "fallDamageMultiplier", baseMultiplier = 0.12}
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
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()	
		
		status.modifyResourcePercentage("health", 0.0006 * dt)
		
	end
end

function 
	checkWeapons()
	local weapons=weaponCheck({"bioweapon"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end