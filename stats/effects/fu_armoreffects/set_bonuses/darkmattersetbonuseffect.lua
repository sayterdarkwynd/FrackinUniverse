require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_darkmatterset"

armorBonus={
	{stat = "critDamage", amount = 0.5},
	{stat = "darknessImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.regenHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		effect.setStatModifierGroup(effectHandlerList.regenHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*0.004}})
		--status.modifyResourcePercentage("health", 0.004 * dt)
	end
end
