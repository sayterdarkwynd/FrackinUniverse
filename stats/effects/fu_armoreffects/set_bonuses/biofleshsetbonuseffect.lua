require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_biofleshset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.15} }

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "energyRegenPercentageRate", amount = 1.05},
	{stat = "energyRegenBlockDischarge", amount = -2}
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

	local hPerc = world.entityHealth(entity.id())
	if hPerc[1] == 0 or hPerc[2] == 0 then return end
	
	if ((hPerc[1] / hPerc[2]) * 100) >= 50 then 
	  return 
	else
	  status.modifyResourcePercentage("health", 0.01)
	end
	script.setUpdateDelta(60)

	mcontroller.controlModifiers({
		groundMovementModifier = 1.3,
		runModifier = 1.3,
		jumpModifier = 1.3
	})

end

function checkWeapons()
	local weapons=weaponCheck({"bioweapon"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end