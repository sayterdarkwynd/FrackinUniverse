setName="fu_steampunkset"

weaponBonus={
	{stat = "maxEnergy", baseMultiplier = 1.25},
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "fireStatusImmunity", amount = 1.0},
	{stat = "breathProtection", amount = 1},
	{stat = "electricStatusImmunity", amount = 1.0}
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

	mcontroller.controlModifiers({
		speedModifier = 1.05
	})
end

function 
	checkWeapons()
	local weapons=weaponCheck({"tesla","electric","energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end