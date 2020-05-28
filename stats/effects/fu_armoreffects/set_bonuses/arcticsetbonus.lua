require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1}
}

setName="fu_arcticset"

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end
