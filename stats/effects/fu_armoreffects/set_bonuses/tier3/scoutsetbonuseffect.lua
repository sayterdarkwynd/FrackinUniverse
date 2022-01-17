require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_scoutset"

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "protoImmunity", amount = 1},
	{stat = "maxBreath", amount = 800},
	{stat = "energyRegenPercentageRate", baseMultiplier = 1.08},
	{stat = "energyRegenBlockTime", baseMultiplier = 0.9}
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