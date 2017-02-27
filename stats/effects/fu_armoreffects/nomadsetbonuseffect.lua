setName="fu_nomadset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.10}
  }
  
armorBonus2={
	{stat = "blacktarImmunity", amount = 1},
	{stat = "quicksandImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "sandstormImmunity", amount = 1},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.20},
	{stat = "maxHealth", baseMultiplier = 1.15},
	{stat = "maxEnergy", baseMultiplier = 1.10}
}

armorBonus={
	{stat = "blacktarImmunity", amount = 1},
	{stat = "quicksandImmunity", amount = 1},
	{stat = "sandstormImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	checkWeapons()
	armorHandle=effect.addStatModifierGroup(armorBonus)
	if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
		effect.setStatModifierGroup(armorHandle,armorBonus2)
	end
    
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
	if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark") then--optional condition to have different armor bonuses
		effect.setStatModifierGroup(armorHandle,armorBonus2)
	else
		effect.setStatModifierGroup(armorHandle,armorBonus1)
	end
end

function checkWeapons()
	if weaponCheck("either",{"dagger"}) then--set both for dual wield required, or leave as is for "if any hand, do."
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end