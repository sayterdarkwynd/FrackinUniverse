require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_xithricitesetkhe"
setEffects={"regeneratingshield_hp-100-10-3","regeneratingshieldindicatordreamer"}

shellBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	
	{ stat = "iceStatusImmunity", amount = 1},
	{ stat = "snowslowImmunity", amount = 1},
	{ stat = "slushslowImmunity", amount = 1},
	{ stat = "liquidnitrogenImmunity", amount = 1},
	{ stat = "iceslipImmunity", amount = 1},
	{ stat = "ffextremecoldImmunity", amount = 1},
	{ stat = "biomecoldImmunity", amount = 1},
	
	{ stat = "fireStatusImmunity", amount = 1},
	{ stat = "lavaImmunity", amount = 1},
	{ stat = "ffextremeheatImmunity", amount = 1},
	{ stat = "biomeheatImmunity", amount = 1}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "insanityImmunity", amount = 1},
	{stat = "waterbreathProtection", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.shellBonusHandle=effect.addStatModifierGroup({})
	
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
	checkShell(not on)
end

function checkShell(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,{}) return end
	local rsp=status.stat("regeneratingshieldpercent")
	if rsp > 0.05 then
		effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,shellBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.shellBonusHandle,{})
	end
end