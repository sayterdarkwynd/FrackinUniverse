require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_phaseset"

armorBonus={
	{stat ="electricStatusImmunity" , amount = 1 },
	{stat ="biomeelectricImmunity" , amount = 1 },
	{stat ="pressureProtection" , amount = 1 },
	{stat ="extremepressureProtection" , amount = 1 },
	{stat ="critChance" , amount = 3 },
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "clayslowImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "jungleslowImmunity", amount = 1},
	{stat = "quicksandImmunity", amount = 1},
	{stat = "honeyslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1}   
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
		mcontroller.controlModifiers({speedModifier = 1.20,airJumpModifier = 1.20})
		setRegen(0.008)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
		setRegen(0.0)
	end
end
