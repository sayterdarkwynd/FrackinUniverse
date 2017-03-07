setName="fu_plebianset"

armorEffect={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
{stat = "shieldRegen", baseMultiplier = 1.25},
{stat = "shieldHealth", baseMultiplier = 1.25},
{stat = "perfectBlockLimitRegen", baseMultiplier = 1.25},
{stat="fireResistance", amount=0.15},
{stat="grit", amount=0.25}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
if not checkSetWorn(self.setBonusCheck) then
	effect.expire()
end
end