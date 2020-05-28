require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_shoggothset"

armorBonus={
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "shadowgasImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "breathProtection", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "protoImmunity", amount = 1},
	{stat = "shadowImmunity", amount = 1},
	{stat = "pressureImmunity", amount = 1},
	{stat = "darknessImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1}
}

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
