require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_assaultset"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.15}
}

armorBonus={
  {stat = "breathProtection", amount = 1.0},
  {stat = "gasImmunity", amount = 1.0},
  {stat = "liquidnitrogenImmunity", amount = 1.0},
  {stat = "biomecoldImmunity", amount = 1.0} 
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
		effect.setStatModifierGroup(
		effectHandlerList.armorBonusHandle,armorBonus)
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