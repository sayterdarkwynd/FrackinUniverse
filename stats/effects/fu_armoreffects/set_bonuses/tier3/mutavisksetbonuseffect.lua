require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_mutaviskset"

armorBonus={
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.75}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		--fart
	end
end
