require "/stats/effects/fu_armoreffects/setbonuses_common.lua"


setName="fu_swashbucklerset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.075}
}

armorBonus={
	{stat = "foodDelta", baseMultiplier = 0.8}
}


function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
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
	local weapons=weaponCheck({"rapier","pistol"})
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,level*2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,level))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end