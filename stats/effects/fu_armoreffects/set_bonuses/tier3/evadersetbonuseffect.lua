require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_evaderset"

weaponBonus1={
	{stat = "physicalResistance", amount = 0.08}
}

armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
	{stat = "shieldBonusShield", amount = 0.25},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

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
	local weapons=weaponCheck({"sword","shortsword","longsword","broadsword","rapier","katana"})
	local shield=weaponCheck({"shield"})
	if weapons["either"] and shield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
