require "/stats/effects/fu_armoreffects/setbonuses_common.lua"


setName="fu_swashbucklerset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.075}
}
weaponBonus2={
	{stat = "powerMultiplier", baseMultiplier = 1.15}
}

armorBonus={
	{stat = "foodDelta", baseMultiplier = 0.8}
}


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
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus2,level))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,level))
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end