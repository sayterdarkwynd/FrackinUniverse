setName="fu_x10set"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.20},
	{stat = "critChance", amount = 2}
}

armorBonus={

}

armorEffect={
	{stat = "breathProtection", amount = 1.0},
	{stat = "gasImmunity", amount = 1.0},
	{stat = "liquidnitrogenImmunity", amount = 1.0},
	{stat = "biomecoldImmunity", amount = 1.0},
	{stat = "fallDamageMultiplier", amount = 0.70}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
	mcontroller.controlModifiers({
		airJumpModifier = 1.2
	})
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","energy"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end