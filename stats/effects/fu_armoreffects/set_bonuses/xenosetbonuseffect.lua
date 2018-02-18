setName="fu_xenoset"

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

armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	weaponBonusHandle=effect.addStatModifierGroup({})
	armorBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	sb.logInfo(sb.printJson(weapons))
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
else
	checkWeapons()
end
sb.logInfo(sb.printJson(weapons))
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