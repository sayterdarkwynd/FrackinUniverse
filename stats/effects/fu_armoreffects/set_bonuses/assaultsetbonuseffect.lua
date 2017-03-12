require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_assaultset"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.15}
}

armorBonus={
  {stat = "iceResistance", amount = 0.20},
  {stat = "physicalResistance", amount = 0.20},
  {stat = "breathProtection", amount = 1.0},
  {stat = "gasImmunity", amount = 1.0},
  {stat = "liquidnitrogenImmunity", amount = 1.0},
  {stat = "biomecoldImmunity", amount = 1.0} 
}

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
	mcontroller.controlModifiers({
		airJumpModifier = 1.2
	})
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end