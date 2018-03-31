require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_grapheneset"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.25}
}

armorBonus={
  {stat = "electricStatusImmunity", amount = 1.0},
  {stat = "stunImmunity", amount = 1.0}
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
		airJumpModifier = 1.05,
		speedModifier = 1.05
	})
end

function checkWeapons()
	local weapons=weaponCheck({"energy","plasma"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end