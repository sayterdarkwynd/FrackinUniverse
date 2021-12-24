require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_arcticset"

armorEffect={
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end
