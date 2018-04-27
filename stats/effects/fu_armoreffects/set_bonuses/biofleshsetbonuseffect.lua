setName="fu_biofleshset"

weaponBonus={ {stat = "powerMultiplier", amount = 0.15} }

armorBonus={
	{stat = "pusImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
	if ((hPerc[1] / hPerc[2]) * 100) >= 50 then return end

	script.setUpdateDelta(60)
	status.modifyResourcePercentage("health", 0.01)
	effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", amount = 1.05}})
	effect.addStatModifierGroup({{stat = "energyRegenBlockDischarge", amount = -2}})
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