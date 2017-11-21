require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_scoutset"

weaponBonus={}

armorBonus={
  {stat = "gasImmunity", amount = 1.0},
  {stat = "maxBreath", amount = 800},
  {stat = "protoImmunity", amount = 1.0},
  {stat = "energyRegenBlockTime", baseMultiplier = 0.9},
  {stat = "energyRegenPercentageRate", amount = 0.08}
}

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
	end
end
