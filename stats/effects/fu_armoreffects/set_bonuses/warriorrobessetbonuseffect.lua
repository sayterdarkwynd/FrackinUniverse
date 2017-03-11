setName="fu_warriorrobesset"

armorEffect={
	{stat = "shadowImmunity", amount = 1},
	{stat = "shadowResistance", amount = 1},
	{stat = "cosmicResistance", amount = 0.3},
	{stat = "shockResistance", amount = 0.3},
	{stat = "radiationResistance", amount = 0.3},
	{stat = "insanityImmunity", amount = 1},
	{stat = "critChance", amount = 8},
	{stat = "foodDelta", baseMultiplier = 0.8}
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