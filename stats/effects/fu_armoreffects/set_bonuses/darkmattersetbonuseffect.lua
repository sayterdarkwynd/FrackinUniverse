require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_darkmatterset"

armorBonus={
  {stat = "critBonus", baseMultiplier = 1.5},
  {stat = "darknessImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(armorBonusHandle,armorBonus)
		status.modifyResourcePercentage("health", 0.004 * dt)
	end
end
