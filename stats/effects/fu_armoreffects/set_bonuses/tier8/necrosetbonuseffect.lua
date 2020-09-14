require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_necroset"

weaponBonus={
	{stat = "critChance", amount = 3.5}
}

armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "breathAmount", baseMultiplier = 3.50}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("undyingresolve30")
		removePetBuffs()
		effect.expire()
	else
		setPetBuffs({"immortalresolve05"})
		status.addEphemeralEffect("undyingresolve30")
		checkWeapons()
	end
end

function checkWeapons()
	local weaponSword=weaponCheck({"elder","precursor"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end