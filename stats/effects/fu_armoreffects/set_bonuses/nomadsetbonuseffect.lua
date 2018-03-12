require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
  {stat = "powerMultiplier", amount = 0.15}
}

armorBonus2={
  {stat = "fireStatusImmunity", amount = 1},
  {stat = "fireResistance", amount = 0.30},
  {stat = "quicksandImmunity", amount = 1},
  {stat = "sandstormImmunity", amount = 1},
  {stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

armorBonus={
  {stat = "fireStatusImmunity", amount = 1},
  {stat = "quicksandImmunity", amount = 1},
  {stat = "sandstormImmunity", amount = 1},
  {stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

setName="fu_nomadset"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
		effect.setStatModifierGroup(armorBonusHandle,armorBonus2)
	end
	
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
	if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus2)
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","knife","shortspear"})
        if weapons["either"] then
	  effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
        else
	  effect.setStatModifierGroup(weaponBonusHandle,{})
        end
end