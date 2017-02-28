armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
	{stat = "shieldRegen", baseMultiplier = 1.25},
	{stat = "shieldHealth", baseMultiplier = 1.25},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.25}
}

setName="fu_plebianset"

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end