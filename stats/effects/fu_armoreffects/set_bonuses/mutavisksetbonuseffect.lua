require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_mutaviskset"

weaponBonus={}

armorBonus={
	{stat = "ffextremeradiationImmunity", amount = 1.0},
	{stat = "biomeradiationImmunity", amount = 1.0},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.75}
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
	end
end
