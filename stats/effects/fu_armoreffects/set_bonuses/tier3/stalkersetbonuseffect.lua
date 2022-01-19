require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_stalkerset"

armorBonus={
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.875},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
}

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critChance", amount = 3}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({airJumpModifier = 1.08})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"sniperrifle", "bow", "crossbow"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end