require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_junkerset"

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "maxBreath", amount = 800},
	{stat = "energyRegenPercentageRate", baseMultiplier = 1.15},
	{stat = "energyRegenBlockTime", baseMultiplier = 0.9},
	{stat = "bombtechBonus", amount = 4.5},
	{stat = "dashtechBonus", amount = 0.35},
	{stat = "dodgetechBonus", amount = 0.35},
	{stat = "jumptechBonus", amount = 0.15}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
