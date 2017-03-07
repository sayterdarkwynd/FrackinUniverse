setName="fu_swashbucklerset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.075}
}

armorBonus={
	{stat = "iceResistance", amount = 0.15},
	{stat = "foodDelta", baseMultiplier = 0.8},
	{stat = "shockResistance", amount = 0.15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	level=checkSetLevel(self.setBonusCheck)
	if level==0 then
		effect.expire()
	else
	checkWeapons()
	end
	mcontroller.controlModifiers({
		airJumpModifier = 1.08
	})
end

function 
	checkWeapons()
	local weapons=weaponCheck({"shortsword"})
	if weapons["both"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,2*level))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,level))
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end