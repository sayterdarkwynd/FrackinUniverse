require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/stats/effects/fu_statusUtil.lua"
setName="fu_starkillerset"

armorBonus={
	 { stat = "maxHealth", effectiveMultiplier = 1.25},
	 { stat = "maxEnergy", effectiveMultiplier = 1.25},
	 { stat = "powerMultiplier", effectiveMultiplier = 1.25},
	 { stat = "protection", effectiveMultiplier = 1.25}
}

armorEffect={
	{stat="breathProtection",amount= 1},
	{stat= "extremepressureProtection",amount= 1},
	{stat= "waterbreathProtection",amount= 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
	end
end

function checkArmor()
	daytime = daytimeCheck()
	underground = undergroundCheck()
	if daytime and not underground then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end
