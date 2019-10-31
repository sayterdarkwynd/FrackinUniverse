require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={}

armorEffect={
	{stat = "iceslipImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "lethalColdImmunity", amount = 1}
}

setName="fu_arcticset"

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
